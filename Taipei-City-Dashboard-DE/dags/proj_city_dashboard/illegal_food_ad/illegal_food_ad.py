from airflow import DAG
from operators.common_pipeline import CommonDag


def _illegal_food_ad(**kwargs):
    import re
    import time

    import pandas as pd
    import requests
    from bs4 import BeautifulSoup
    from sqlalchemy import create_engine
    from utils.load_stage import (
        save_dataframe_to_postgresql,
        update_lasttime_in_data_to_dataset_info,
    )

    # Config
    ready_data_db_uri = kwargs.get("ready_data_db_uri")
    dag_infos = kwargs.get("dag_infos")
    dag_id = dag_infos.get("dag_id")
    load_behavior = dag_infos.get("load_behavior")
    default_table = dag_infos.get("ready_data_default_table")

    BASE_URL = "https://pmds.fda.gov.tw/illegalad/CaseSearch.aspx"
    # 台北市 → city="台北"，新北市 → city="雙北"（city allowlist 規範）
    CITIES = [("臺北市", "台北"), ("新北市", "雙北")]

    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})

    def get_tokens(html):
        vs = re.search(r'id="__VIEWSTATE"[^>]*value="([^"]*)"', html)
        ev = re.search(r'id="__EVENTVALIDATION"[^>]*value="([^"]*)"', html)
        vsg = re.search(r'id="__VIEWSTATEGENERATOR"[^>]*value="([^"]*)"', html)
        return (
            vs.group(1) if vs else "",
            ev.group(1) if ev else "",
            vsg.group(1) if vsg else "",
        )

    def parse_roc_date(s):
        """民國年 '113/05/15' → datetime，失敗回 NaT。"""
        try:
            parts = str(s).strip().split("/")
            if len(parts) == 3:
                year = int(parts[0]) + 1911
                return pd.Timestamp(year=year, month=int(parts[1]), day=int(parts[2]))
        except Exception:
            pass
        return pd.NaT

    def parse_table(soup):
        records = []
        table = soup.find("table", class_="table_list")
        if not table:
            return records
        rows = table.find_all("tr")[1:]  # 跳過 header
        for row in rows:
            cols = row.find_all("td")
            if len(cols) < 4:
                continue
            product = cols[1].get_text(strip=True)
            company = cols[2].get_text(strip=True)
            # 處分機關/日期/法條 以 <br> 分隔
            penalty_text = cols[3].get_text("\n")
            penalty_parts = [t.strip() for t in penalty_text.split("\n") if t.strip()]
            organ = penalty_parts[0] if len(penalty_parts) > 0 else ""
            date_str = penalty_parts[1] if len(penalty_parts) > 1 else ""
            law = penalty_parts[2] if len(penalty_parts) > 2 else ""
            records.append({
                "product": product,
                "company": company,
                "organ": organ,
                "date_str": date_str,
                "law": law,
            })
        return records

    def has_next_page(soup):
        """判斷是否還有下一頁（下一頁按鈕存在且非 disabled）。"""
        pager = soup.find(id="ctl00_Content_DataPager1")
        if not pager:
            return False, None
        next_link = pager.find("a", class_="next")
        if not next_link:
            return False, None
        href = next_link.get("href", "")
        m = re.search(r"__doPostBack\('([^']+)'", href)
        if not m:
            return False, None
        return True, m.group(1)

    all_records = []
    for city_raw, city_label in CITIES:
        # 初始 GET 取得 ASP.NET token
        resp = session.get(BASE_URL, timeout=30)
        resp.raise_for_status()
        vs, ev, vsg = get_tokens(resp.text)

        # 第一頁搜尋 POST（以 處分機關 篩選縣市）
        base_form = {
            "__VIEWSTATE": vs,
            "__VIEWSTATEGENERATOR": vsg,
            "__EVENTVALIDATION": ev,
            "ctl00$Content$txtProductName": "",
            "ctl00$Content$txtVioCompany": "",
            "ctl00$Content$ddlCaseSourceOrgan": "全部",
            "ctl00$Content$ddlTransferOrgan": city_raw,
            "ctl00$Content$chklstMediaType$0": "on",
            "ctl00$Content$chklstMediaType$1": "on",
            "ctl00$Content$chklstMediaType$2": "on",
            "ctl00$Content$chklstMediaType$3": "on",
            "ctl00$Content$chklstMediaType$4": "on",
            "ctl00$Content$txtPunishLaw": "",
            "ctl00$Content$btnSubmit": "查詢",
        }
        resp = session.post(BASE_URL, data=base_form, timeout=60)
        resp.raise_for_status()

        city_records = []
        while True:
            soup = BeautifulSoup(resp.text, "html.parser")
            city_records.extend(parse_table(soup))

            has_next, next_target = has_next_page(soup)
            if not has_next:
                break

            vs, ev, vsg = get_tokens(resp.text)
            page_form = {
                "__VIEWSTATE": vs,
                "__VIEWSTATEGENERATOR": vsg,
                "__EVENTVALIDATION": ev,
                "__EVENTTARGET": next_target,
                "__EVENTARGUMENT": "",
                "ctl00$Content$txtProductName": "",
                "ctl00$Content$txtVioCompany": "",
                "ctl00$Content$ddlCaseSourceOrgan": "全部",
                "ctl00$Content$ddlTransferOrgan": city_raw,
                "ctl00$Content$chklstMediaType$0": "on",
                "ctl00$Content$chklstMediaType$1": "on",
                "ctl00$Content$chklstMediaType$2": "on",
                "ctl00$Content$chklstMediaType$3": "on",
                "ctl00$Content$chklstMediaType$4": "on",
                "ctl00$Content$txtPunishLaw": "",
            }
            resp = session.post(BASE_URL, data=page_form, timeout=60)
            resp.raise_for_status()
            time.sleep(0.5)

        for r in city_records:
            r["city"] = city_label
        all_records.extend(city_records)

    # Transform
    raw_data = pd.DataFrame(all_records)
    data = raw_data.copy()
    data["data_time"] = data["date_str"].apply(parse_roc_date)
    data = data.dropna(subset=["data_time"])
    ready_data = (
        data[["data_time", "city", "product", "company", "organ", "law"]]
        .sort_values("data_time", ascending=False)
        .reset_index(drop=True)
    )

    # Load
    engine = create_engine(ready_data_db_uri)
    save_dataframe_to_postgresql(
        engine,
        data=ready_data,
        load_behavior=load_behavior,
        default_table=default_table,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="illegal_food_ad")
dag.create_dag(etl_func=_illegal_food_ad)
