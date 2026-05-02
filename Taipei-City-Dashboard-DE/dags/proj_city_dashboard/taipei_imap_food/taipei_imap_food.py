from airflow import DAG
from operators.common_pipeline import CommonDag


def _regen_geojson(engine):
    import json
    import os

    from sqlalchemy import text

    features = []
    month_stats = {}

    with engine.connect() as conn:
        rows = conn.execute(text("""
            SELECT reg_no, name, address, district, result,
                   TO_CHAR(data_time AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') as month,
                   lat, lng
            FROM taipei_imap_food
            WHERE lat IS NOT NULL AND lng IS NOT NULL
            ORDER BY month ASC, data_time ASC
        """)).fetchall()

    for row in rows:
        reg_no, name, address, district, result, month, lat, lng = row
        features.append({
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [float(lng), float(lat)]},
            "properties": {
                "reg_no": reg_no, "name": name,
                "address": address, "district": district,
                "result": result, "month": month,
            }
        })
        if month not in month_stats:
            month_stats[month] = {"合格": 0, "正在複查": 0, "不合格": 0}
        if result and result.startswith("A"):
            month_stats[month]["合格"] += 1
        elif result == "B1":
            month_stats[month]["正在複查"] += 1
        elif result:
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
    out_path = os.path.join(out_dir, "taipei_imap_food.geojson")
    try:
        os.makedirs(out_dir, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(geojson, f, ensure_ascii=False)
        print(f"GeoJSON updated → {out_path} ({len(features)} features, {len(available_months)} months)")
    except Exception as e:
        print(f"GeoJSON write skipped ({e})")


def _taipei_imap_food(**kwargs):
    import json
    import re
    import time

    import pandas as pd
    import requests
    from sqlalchemy import create_engine, text
    from utils.load_stage import update_lasttime_in_data_to_dataset_info
    from utils.transform_geometry import add_point_wkbgeometry_column_to_df

    # Config
    ready_data_db_uri = kwargs.get("ready_data_db_uri")
    dag_infos = kwargs.get("dag_infos")
    dag_id = dag_infos.get("dag_id")
    default_table = dag_infos.get("ready_data_default_table")
    FROM_CRS = 4326

    BASE_URL = "https://imap.health.gov.tw/App_Prog/MapMetro2.aspx"
    DISTRICTS = {
        "0101": "松山區", "0102": "大安區", "0109": "大同區", "0110": "中山區",
        "0111": "內湖區", "0112": "南港區", "0115": "士林區", "0116": "北投區",
        "0117": "信義區", "0118": "中正區", "0119": "萬華區", "0120": "文山區",
    }

    # Extract — establish session and get ASP.NET form tokens once
    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})
    init_resp = session.get(BASE_URL, timeout=30)
    init_resp.raise_for_status()

    vs_match = re.search(r'id="__VIEWSTATE"[^>]*value="([^"]*)"', init_resp.text)
    ev_match = re.search(r'id="__EVENTVALIDATION"[^>]*value="([^"]*)"', init_resp.text)
    vsg_match = re.search(r'id="__VIEWSTATEGENERATOR"[^>]*value="([^"]*)"', init_resp.text)
    if not vs_match or not ev_match:
        raise RuntimeError("Failed to extract ASP.NET form tokens from iMAP")
    vs = vs_match.group(1)
    ev = ev_match.group(1)
    vsg = vsg_match.group(1) if vsg_match else ""

    ajax_headers = {
        "X-Requested-With": "XMLHttpRequest",
        "X-MicrosoftAjax": "Delta=true",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Referer": BASE_URL,
    }

    all_records = []
    for code, name in DISTRICTS.items():
        post_data = {
            "ctl00$ScriptManager1": "ctl00$ContentPlaceHolder1$UpdatePanel1|ctl00$ContentPlaceHolder1$btnSearch",
            "__EVENTTARGET": "ctl00$ContentPlaceHolder1$btnSearch",
            "__EVENTARGUMENT": "",
            "__ASYNCPOST": "true",
            "__VIEWSTATE": vs,
            "__VIEWSTATEGENERATOR": vsg,
            "__EVENTVALIDATION": ev,
            "ctl00$ContentPlaceHolder1$type1": "radioFood",
            "ctl00$ContentPlaceHolder1$Food_Stations": "radioArea",
            "ctl00$ContentPlaceHolder1$rdlArea": code,
        }
        resp = session.post(BASE_URL, data=post_data, headers=ajax_headers, timeout=60)
        resp.raise_for_status()

        m = re.search(r'cblChartValue1"[^>]*style="display: none;">(.*?)</span>', resp.text, re.DOTALL)
        if not m:
            m = re.search(r'cblChartValue1"[^>]*>(.*?)</span>', resp.text, re.DOTALL)
        if m:
            content = m.group(1).strip()
            if content.startswith("["):
                records = json.loads(content)
                for r in records:
                    r["district"] = name
                all_records.extend(records)

        # Refresh tokens from UpdatePanel response (hiddenField format)
        vs_new = re.search(r'hiddenField\|__VIEWSTATE\|([^|]+)\|', resp.text)
        ev_new = re.search(r'hiddenField\|__EVENTVALIDATION\|([^|]+)\|', resp.text)
        if vs_new:
            vs = vs_new.group(1)
        if ev_new:
            ev = ev_new.group(1)

        time.sleep(1)

    raw_data = pd.DataFrame(all_records)

    # Transform
    data = raw_data.copy()
    data["lat"] = pd.to_numeric(data["latitude"], errors="coerce")
    data["lng"] = pd.to_numeric(data["longitude"], errors="coerce")
    data = data.dropna(subset=["lat", "lng"])
    data = data[(data["lat"] != 0) & (data["lng"] != 0)]
    data["data_time"] = pd.to_datetime(data["check_date"], format="%Y.%m.%d", errors="coerce")
    data["data_time"] = data["data_time"].fillna(pd.Timestamp.now().normalize())
    data = data.rename(columns={
        "store_name": "name",
        "store_address": "address",
        "store_regNum": "reg_no",
        "check_result": "result",
        "check_date": "check_date_str",
    })
    data = data.drop_duplicates(subset=["store_id"])

    gdata = add_point_wkbgeometry_column_to_df(data, data["lng"], data["lat"], from_crs=FROM_CRS)
    gdata = gdata.drop(columns="geometry")

    # 本月份標籤（台北時間）
    current_month = pd.Timestamp.now(tz="Asia/Taipei").strftime("%Y-%m")
    gdata["month"] = current_month

    ready_data = gdata[["data_time", "name", "reg_no", "address", "district", "result", "lat", "lng", "wkb_geometry", "month"]]

    # Load — monthly snapshot upsert (INSERT ... ON CONFLICT (reg_no, month) DO UPDATE)
    engine = create_engine(ready_data_db_uri)
    with engine.begin() as conn:
        for _, row in ready_data.iterrows():
            conn.execute(text("""
                INSERT INTO taipei_imap_food
                    (data_time, name, reg_no, address, district, result, lat, lng, wkb_geometry, month)
                VALUES
                    (:data_time, :name, :reg_no, :address, :district, :result, :lat, :lng,
                     ST_GeomFromWKB(:wkb_geometry, 4326), :month)
                ON CONFLICT (reg_no, month) DO UPDATE SET
                    data_time = EXCLUDED.data_time,
                    name      = EXCLUDED.name,
                    address   = EXCLUDED.address,
                    district  = EXCLUDED.district,
                    result    = EXCLUDED.result,
                    lat       = EXCLUDED.lat,
                    lng       = EXCLUDED.lng,
                    wkb_geometry = EXCLUDED.wkb_geometry
            """), {
                "data_time":     row["data_time"].isoformat() if hasattr(row["data_time"], "isoformat") else str(row["data_time"]),
                "name":          row["name"],
                "reg_no":        row["reg_no"],
                "address":       row["address"],
                "district":      row["district"],
                "result":        row["result"],
                "lat":           float(row["lat"]),
                "lng":           float(row["lng"]),
                "wkb_geometry":  row["wkb_geometry"].wkb_hex if hasattr(row["wkb_geometry"], "wkb_hex") else str(row["wkb_geometry"]),
                "month":         row["month"],
            })

    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())

    # Regen GeoJSON after each successful ETL run
    _regen_geojson(engine)


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="taipei_imap_food")
dag.create_dag(etl_func=_taipei_imap_food)
