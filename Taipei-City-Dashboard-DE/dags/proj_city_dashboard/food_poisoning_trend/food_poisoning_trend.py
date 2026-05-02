from airflow import DAG
from operators.common_pipeline import CommonDag


def _food_poisoning_trend(**kwargs):
    import pandas as pd
    import requests
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
    URL = "https://data.fda.gov.tw/data/opendata/export/114/json"
    MONTH_MAP = {"一月": 1, "二月": 2, "三月": 3, "四月": 4, "五月": 5, "六月": 6,
                 "七月": 7, "八月": 8, "九月": 9, "十月": 10, "十一月": 11, "十二月": 12}

    # Extract
    res = requests.get(URL, timeout=30)
    res.raise_for_status()
    raw_data = pd.DataFrame(res.json())

    # Transform
    data = raw_data.copy()
    # remove multi-year range rows (e.g. "70年至74年")
    data = data[~data["年度"].str.contains("至", na=False)]
    # convert ROC year to AD year (e.g. "70年" -> 1981)
    data["year"] = data["年度"].str.extract(r"(\d+)").astype(int) + 1911
    # keep only recent 10 years
    data = data[data["year"] >= data["year"].max() - 9]
    # melt months into rows
    month_cols = list(MONTH_MAP.keys())
    melted = data.melt(id_vars=["year"], value_vars=month_cols, var_name="month_zh", value_name="cases")
    melted["month"] = melted["month_zh"].map(MONTH_MAP)
    melted["cases"] = pd.to_numeric(melted["cases"], errors="coerce").fillna(0).astype(int)
    melted["data_time"] = pd.to_datetime(melted["year"].astype(str) + "-" + melted["month"].astype(str).str.zfill(2) + "-01")
    ready_data = melted[["data_time", "year", "month", "cases"]].sort_values(["year", "month"]).reset_index(drop=True)

    # Load
    engine = create_engine(ready_data_db_uri)
    save_dataframe_to_postgresql(
        engine,
        data=ready_data,
        load_behavior=load_behavior,
        default_table=default_table,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="food_poisoning_trend")
dag.create_dag(etl_func=_food_poisoning_trend)
