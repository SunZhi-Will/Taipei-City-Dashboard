from airflow import DAG
from operators.common_pipeline import CommonDag


def _wholesale_pesticide_inspection(**kwargs):
    import io
    import re
    from datetime import datetime, timedelta

    import pandas as pd
    import pdfplumber
    import requests
    from sqlalchemy import create_engine, text
    from utils.load_stage import update_lasttime_in_data_to_dataset_info
    from utils.transform_geometry import add_point_wkbgeometry_column_to_df

    ready_data_db_uri = kwargs.get("ready_data_db_uri")
    dag_infos = kwargs.get("dag_infos")
    dag_id = dag_infos.get("dag_id")
    default_table = dag_infos.get("ready_data_default_table")
    FROM_CRS = 4326

    # 4 個批發市場 GPS（依公開地址）
    MARKET_COORDS = {
        "第一批發市場": (25.0245, 121.5023),
        "第二批發市場": (25.0683, 121.5394),
        "三重": (25.0697, 121.4946),
        "板橋": (25.0146, 121.4823),
    }

    TAPMC_LIST = "https://www.tapmc.com.tw/Pages/NewsList/2"
    TAPMC_DETAIL_BASE = "https://www.tapmc.com.tw"
    NTPM_LIST = "https://www.ntpm.com.tw/NewsList.aspx/9"
    NTPM_DETAIL_BASE = "https://www.ntpm.com.tw"

    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})

    def list_recent_news(list_url, detail_pattern, limit=10):
        resp = session.get(list_url, timeout=30)
        resp.raise_for_status()
        urls = re.findall(detail_pattern, resp.text)
        seen, out = set(), []
        for u in urls:
            if u in seen:
                continue
            seen.add(u)
            out.append(u)
            if len(out) >= limit:
                break
        return out

    def get_pdf_url(detail_url):
        resp = session.get(detail_url, timeout=30)
        resp.raise_for_status()
        m = re.search(r'href="(/DL\.ashx\?f=[A-F0-9]+&s=Web_News)"', resp.text)
        return m.group(1) if m else None

    def download_pdf(url):
        full_url = url if url.startswith("http") else (TAPMC_DETAIL_BASE if "tapmc" in url else NTPM_DETAIL_BASE) + url
        # detect base by current context — simplest: attempt both
        resp = session.get(full_url, timeout=60)
        resp.raise_for_status()
        return resp.content

    def roc_to_date(s):
        # 1150428 → 2026-04-28；115/04/28 → 2026-04-28
        s = s.strip().replace("年", "/").replace("月", "/").replace("日", "").replace(".", "/")
        if "/" in s:
            parts = s.split("/")
            y = int(parts[0]) + 1911
            return datetime(y, int(parts[1]), int(parts[2]))
        if len(s) == 7 and s.isdigit():
            return datetime(int(s[:3]) + 1911, int(s[3:5]), int(s[5:7]))
        return None

    rows = []

    # === 北農（tapmc）：只列不合格 ===
    tapmc_detail_pattern = r'href="(/Pages/NewsDtl/N\d{10})"'
    tapmc_news = list_recent_news(TAPMC_LIST, tapmc_detail_pattern, limit=10)
    for path in tapmc_news:
        try:
            detail_url = TAPMC_DETAIL_BASE + path
            pdf_path = get_pdf_url(detail_url)
            if not pdf_path:
                continue
            pdf_bytes = session.get(TAPMC_DETAIL_BASE + pdf_path, timeout=60).content
            with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
                for page in pdf.pages:
                    for table in page.extract_tables() or []:
                        for r in table:
                            if not r or not r[0] or not str(r[0]).strip().isdigit():
                                continue
                            # cols: No, 檢驗日期, 樣品來源, 大代號, 小代號, 名稱, 樣品名稱, 品名代號, 檢出藥劑, 判定結果
                            no_, dt_, market, _, _, source_org, product_name, product_code, pesticides, result = (r + [None] * 10)[:10]
                            d = roc_to_date(str(dt_)) if dt_ else None
                            if not d or not product_name:
                                continue
                            lat, lng = MARKET_COORDS.get(str(market).strip(), (None, None))
                            rows.append({
                                "data_time": d,
                                "market": str(market).strip(),
                                "source_dept": "tapmc",
                                "raw_no": str(no_).strip(),
                                "source_org": str(source_org).replace("\n", "").strip() if source_org else None,
                                "origin_city": None,
                                "product_code": str(product_code).strip() if product_code else None,
                                "product_name": str(product_name).strip(),
                                "result": str(result).strip() if result else "不合格",
                                "pesticides": str(pesticides).replace("\n", "; ").strip() if pesticides else None,
                                "lat": lat,
                                "lng": lng,
                            })
        except Exception as e:
            print(f"[tapmc] skip {path}: {e}")

    # === 新北農（ntpm）：列全部抽檢 ===
    ntpm_detail_pattern = r'href="(/NewsDetail/[A-F0-9]+)"'
    ntpm_news = list_recent_news(NTPM_LIST, ntpm_detail_pattern, limit=10)
    for path in ntpm_news:
        try:
            detail_url = NTPM_DETAIL_BASE + path
            pdf_path = get_pdf_url(detail_url)
            if not pdf_path:
                continue
            pdf_bytes = session.get(NTPM_DETAIL_BASE + pdf_path, timeout=60).content
            with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
                for page in pdf.pages:
                    for table in page.extract_tables() or []:
                        for r in table:
                            if not r or not r[0] or not str(r[0]).strip().isdigit():
                                continue
                            # cols: 編號, 市場別, 交易日期, 抽檢日期, 供應代號, 小代號, 轄管團體, 縣市別, 供貨單位, 品名代碼, 抽檢品項, 抽檢結果, 檢出農藥
                            row = (r + [None] * 13)[:13]
                            no_, market, _trade_dt, sample_dt, _, _, _, origin_city, source_org, product_code, product_name, result, pesticides = row
                            d = roc_to_date(str(sample_dt)) if sample_dt else None
                            if not d or not product_name:
                                continue
                            lat, lng = MARKET_COORDS.get(str(market).strip(), (None, None))
                            rows.append({
                                "data_time": d,
                                "market": str(market).strip(),
                                "source_dept": "ntpm",
                                "raw_no": str(no_).strip(),
                                "source_org": str(source_org).replace("\n", "").strip() if source_org else None,
                                "origin_city": str(origin_city).strip() if origin_city else None,
                                "product_code": str(product_code).strip() if product_code else None,
                                "product_name": str(product_name).strip(),
                                "result": str(result).strip() if result else None,
                                "pesticides": str(pesticides).replace("\n", "; ").strip() if pesticides else None,
                                "lat": lat,
                                "lng": lng,
                            })
        except Exception as e:
            print(f"[ntpm] skip {path}: {e}")

    if not rows:
        print("No rows parsed; skip load.")
        return

    df = pd.DataFrame(rows)
    df = df.dropna(subset=["lat", "lng"])
    df = df[(df["lat"] != 0) & (df["lng"] != 0)]
    if df.empty:
        print("All rows filtered out; skip load.")
        return

    gdf = add_point_wkbgeometry_column_to_df(df, df["lng"], df["lat"], from_crs=FROM_CRS)
    gdf = gdf.drop(columns="geometry")

    # Upsert by unique constraint (data_time, market, raw_no, product_name, source_org)
    engine = create_engine(ready_data_db_uri)
    insert_sql = text(f"""
        INSERT INTO {default_table}
            (data_time, market, source_dept, raw_no, source_org, origin_city,
             product_code, product_name, result, pesticides, lat, lng, wkb_geometry)
        VALUES
            (:data_time, :market, :source_dept, :raw_no, :source_org, :origin_city,
             :product_code, :product_name, :result, :pesticides, :lat, :lng,
             ST_GeomFromWKB(:wkb_geometry, 4326))
        ON CONFLICT (data_time, market, raw_no, product_name, source_org) DO NOTHING
    """)
    with engine.begin() as conn:
        records = gdf.to_dict(orient="records")
        for rec in records:
            conn.execute(insert_sql, rec)

    update_lasttime_in_data_to_dataset_info(engine, dag_id, gdf["data_time"].max())
    print(f"Inserted/upserted {len(records)} rows")

    # Regenerate GeoJSON with monthly snapshots so the frontend map time-scrubber stays current
    _regen_geojson(engine)


def _regen_geojson(engine):
    import json
    import os

    features = []
    month_stats = {}

    with engine.connect() as conn:
        rows = conn.execute(text("""
            SELECT
                market,
                result,
                product_name,
                COALESCE(pesticides, '') AS pesticides,
                TO_CHAR(data_time AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') AS month,
                lat,
                lng
            FROM wholesale_pesticide_inspection
            WHERE lat IS NOT NULL AND lng IS NOT NULL
            ORDER BY month ASC, market, data_time
        """)).fetchall()

    for row in rows:
        market, result, product_name, pesticides, month, lat, lng = row
        features.append({
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [lng, lat]},
            "properties": {
                "market":       market,
                "result":       result,
                "product_name": product_name,
                "pesticides":   pesticides or None,
                "month":        month,
            },
        })
        if month not in month_stats:
            month_stats[month] = {"合格": 0, "不合格": 0}
        if result == "合格":
            month_stats[month]["合格"] += 1
        else:
            month_stats[month]["不合格"] += 1

    available_months = sorted(month_stats.keys(), reverse=True)
    geojson = {
        "type": "FeatureCollection",
        "metadata": {
            "type": "monthly_flat",
            "available_months": available_months,
            "month_stats": month_stats,
        },
        "features": features,
    }

    out_dir = os.environ.get(
        "FRONTEND_MAP_DATA_DIR",
        "/opt/airflow/dags/../../Taipei-City-Dashboard-FE/public/mapData",
    )
    out_path = os.path.join(out_dir, "wholesale_pesticide_inspection.geojson")
    try:
        os.makedirs(out_dir, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(geojson, f, ensure_ascii=False)
        print(f"GeoJSON updated → {out_path} ({len(features)} features, {len(available_months)} months)")
    except Exception as e:
        print(f"GeoJSON write skipped ({e})")


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="wholesale_pesticide_inspection")
dag.create_dag(etl_func=_wholesale_pesticide_inspection)
