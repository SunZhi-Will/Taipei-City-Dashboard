"""
蔬果批發農藥殘留歷史資料補抓腳本
用途：補齊 TAPMC 2026-04-13 起的歷史資料（清單頁只顯示最新5筆，本腳本掃描所有存在的文章）

執行方式（在 airflow-worker 容器內）：
    python3 /opt/airflow/dags/proj_city_dashboard/wholesale_pesticide_inspection/run_history_backfill.py

或從容器外：
    docker exec airflow-worker python3 /opt/airflow/dags/proj_city_dashboard/wholesale_pesticide_inspection/run_history_backfill.py
"""
import io
import json
import os
import re
from datetime import datetime, timedelta

import pdfplumber
import psycopg2
import requests

# ── 設定 ──────────────────────────────────────────────────────────────────
DB_HOST = os.environ.get("DB_DASHBOARD_HOST", "postgres-data")
DB_PORT = int(os.environ.get("DB_DASHBOARD_PORT", "5432"))
DB_NAME = os.environ.get("DB_DASHBOARD_DBNAME", "dashboard")
DB_USER = os.environ.get("DB_DASHBOARD_USER", "postgres")
DB_PASS = os.environ.get("DB_DASHBOARD_PASSWORD", "devpass")

TAPMC_BASE = "https://www.tapmc.com.tw"
TAPMC_LIST = "https://www.tapmc.com.tw/Pages/NewsList/2"
NTPM_BASE = "https://www.ntpm.com.tw"
NTPM_LIST = "https://www.ntpm.com.tw/NewsList.aspx/9"

# 掃描回溯天數（TAPMC 農藥公告從 2026-04-13 開始，設定 30 天足夠）
TAPMC_DAYS_BACK = int(os.environ.get("TAPMC_DAYS_BACK", "30"))

MARKET_COORDS = {
    "第一批發市場": (25.0245, 121.5023),
    "第二批發市場": (25.0683, 121.5394),
    "三重": (25.0697, 121.4946),
    "板橋": (25.0146, 121.4823),
}

FRONTEND_MAP_DATA_DIR = os.environ.get(
    "FRONTEND_MAP_DATA_DIR",
    "/opt/airflow/dags/../../Taipei-City-Dashboard-FE/public/mapData",
)

# ── 工具函數 ──────────────────────────────────────────────────────────────
session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0"})


def roc_to_date(s):
    s = s.strip().replace("年", "/").replace("月", "/").replace("日", "").replace(".", "/")
    if "/" in s:
        parts = s.split("/")
        try:
            y = int(parts[0]) + 1911
            return datetime(y, int(parts[1]), int(parts[2]))
        except Exception:
            return None
    if len(s) == 7 and s.isdigit():
        try:
            return datetime(int(s[:3]) + 1911, int(s[3:5]), int(s[5:7]))
        except Exception:
            return None
    return None


def get_pdf_url_tapmc(detail_url):
    resp = session.get(detail_url, timeout=30)
    m = re.search(r'href="(/DL\.ashx\?f=[A-F0-9]+&s=Web_News)"', resp.text)
    return m.group(1) if m else None


def get_pdf_url_ntpm(detail_url):
    resp = session.get(detail_url, timeout=30)
    m = re.search(r'href="(/DL\.ashx\?f=[A-F0-9]+&s=Web_News)"', resp.text)
    return m.group(1) if m else None


# ── TAPMC 掃描 ────────────────────────────────────────────────────────────
def list_tapmc_news_by_scan(days_back=30):
    """掃描 days_back 天內每天的 N<roc年月日>2xx ID"""
    today = datetime.now()
    found = []
    seen = set()
    for offset in range(days_back):
        dt = today - timedelta(days=offset)
        roc_year = dt.year - 1911
        roc_str = f"{roc_year:03d}{dt.month:02d}{dt.day:02d}"
        for seq_num in range(1, 11):
            seq = f"2{seq_num:02d}"
            nid = f"N{roc_str}{seq}"
            if nid in seen:
                continue
            seen.add(nid)
            path = f"/Pages/NewsDtl/{nid}"
            url = TAPMC_BASE + path
            try:
                r = session.head(url, timeout=5, allow_redirects=False)
                if r.status_code == 200:
                    found.append(path)
                    print(f"[tapmc] 找到: {nid} ({dt.strftime('%Y-%m-%d')})")
            except Exception:
                pass
    # 同時從清單頁補充
    try:
        resp = session.get(TAPMC_LIST, timeout=30)
        list_ids = re.findall(r'(/Pages/NewsDtl/N\d{10})', resp.text)
        for path in list_ids:
            if path not in found:
                found.append(path)
                print(f"[tapmc] 清單頁新增: {path}")
    except Exception as e:
        print(f"[tapmc] 清單頁錯誤: {e}")
    print(f"[tapmc] 共找到 {len(found)} 篇文章")
    return found


def parse_tapmc_pdf(pdf_bytes):
    rows = []
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            for table in page.extract_tables() or []:
                for r in table:
                    if not r or not r[0] or not str(r[0]).strip().isdigit():
                        continue
                    # cols: No, 檢驗日期, 樣品來源(市場), 大代號, 小代號, 名稱, 樣品名稱, 品名代號, 檢出藥劑, 判定結果
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
    return rows


# ── NTPM 清單+解析 ────────────────────────────────────────────────────────
def list_ntpm_news(limit=50):
    resp = session.get(NTPM_LIST, timeout=30)
    paths = re.findall(r'(/NewsDetail/[A-F0-9]+)', resp.text)
    seen, out = set(), []
    for p in paths:
        if p in seen:
            continue
        seen.add(p)
        out.append(p)
        if len(out) >= limit:
            break
    return out


def parse_ntpm_pdf(pdf_bytes):
    rows = []
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
    return rows


# ── 主程式 ────────────────────────────────────────────────────────────────
def main():
    rows = []

    # TAPMC
    tapmc_news = list_tapmc_news_by_scan(days_back=TAPMC_DAYS_BACK)
    for path in tapmc_news:
        try:
            detail_url = TAPMC_BASE + path
            pdf_path = get_pdf_url_tapmc(detail_url)
            if not pdf_path:
                print(f"[tapmc] 無 PDF: {path}")
                continue
            pdf_bytes = session.get(TAPMC_BASE + pdf_path, timeout=60).content
            parsed = parse_tapmc_pdf(pdf_bytes)
            print(f"[tapmc] {path} → {len(parsed)} 筆")
            rows.extend(parsed)
        except Exception as e:
            print(f"[tapmc] 跳過 {path}: {e}")

    # NTPM
    ntpm_news = list_ntpm_news(limit=50)
    print(f"[ntpm] 共找到 {len(ntpm_news)} 篇文章")
    for path in ntpm_news:
        try:
            detail_url = NTPM_BASE + path
            pdf_path = get_pdf_url_ntpm(detail_url)
            if not pdf_path:
                print(f"[ntpm] 無 PDF: {path}")
                continue
            pdf_bytes = session.get(NTPM_BASE + pdf_path, timeout=60).content
            parsed = parse_ntpm_pdf(pdf_bytes)
            print(f"[ntpm] {path} → {len(parsed)} 筆")
            rows.extend(parsed)
        except Exception as e:
            print(f"[ntpm] 跳過 {path}: {e}")

    # 過濾無座標
    rows = [r for r in rows if r.get("lat") and r.get("lng")]
    print(f"\n總解析筆數（有座標）: {len(rows)}")

    if not rows:
        print("無資料，結束。")
        return

    # 寫入 DB
    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASS
    )
    cur = conn.cursor()
    inserted = 0
    for rec in rows:
        try:
            cur.execute("""
                INSERT INTO wholesale_pesticide_inspection
                    (data_time, market, source_dept, raw_no, source_org, origin_city,
                     product_code, product_name, result, pesticides, lat, lng,
                     wkb_geometry)
                VALUES
                    (%(data_time)s, %(market)s, %(source_dept)s, %(raw_no)s, %(source_org)s,
                     %(origin_city)s, %(product_code)s, %(product_name)s, %(result)s,
                     %(pesticides)s, %(lat)s, %(lng)s,
                     ST_SetSRID(ST_MakePoint(%(lng)s, %(lat)s), 4326))
                ON CONFLICT (data_time, market, raw_no, product_name, source_org) DO NOTHING
            """, rec)
            inserted += cur.rowcount
        except Exception as e:
            conn.rollback()
            print(f"  DB 錯誤: {e} | {rec.get('product_name')}")
            continue
    conn.commit()
    print(f"新增寫入 {inserted} 筆（重複略過）")

    # 查詢月份統計
    cur.execute("""
        SELECT source_dept,
               TO_CHAR(data_time AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') as month,
               COUNT(*) as cnt
        FROM wholesale_pesticide_inspection
        WHERE data_time < '2100-01-01'
        GROUP BY source_dept, month
        ORDER BY month DESC, source_dept
    """)
    print("\n── DB 月份統計 ──")
    for row in cur.fetchall():
        print(f"  {row[0]:8s} {row[1]}  {row[2]:5d} 筆")

    # 產生 GeoJSON
    cur.execute("""
        SELECT market, result, product_name,
               COALESCE(pesticides, '') as pesticides,
               TO_CHAR(data_time AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') as month,
               lat::text, lng::text
        FROM wholesale_pesticide_inspection
        WHERE lat IS NOT NULL AND lng IS NOT NULL
          AND data_time < '2100-01-01'
        ORDER BY month ASC, market, data_time
    """)
    db_rows = cur.fetchall()
    conn.close()

    features = []
    month_stats = {}
    for market, result, product_name, pesticides, month, lat, lng in db_rows:
        features.append({
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [float(lng), float(lat)]},
            "properties": {
                "market": market, "result": result,
                "product_name": product_name,
                "pesticides": pesticides or None,
                "month": month,
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

    out_dir = FRONTEND_MAP_DATA_DIR
    out_path = os.path.join(out_dir, "wholesale_pesticide_inspection.geojson")
    try:
        os.makedirs(out_dir, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(geojson, f, ensure_ascii=False)
        print(f"\nGeoJSON 已更新 → {out_path}")
        print(f"  Features: {len(features)} 筆")
        print(f"  月份數: {len(available_months)}")
        print(f"  月份: {available_months}")
    except Exception as e:
        print(f"GeoJSON 寫入失敗: {e}")


if __name__ == "__main__":
    main()
