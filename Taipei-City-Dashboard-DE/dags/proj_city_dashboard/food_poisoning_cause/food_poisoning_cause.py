from airflow import DAG
from operators.common_pipeline import CommonDag


def _food_poisoning_cause(**kwargs):
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
    URL = "https://data.fda.gov.tw/data/opendata/export/115/json"
    CAUSE_COLS = ["腸炎弧菌", "沙門氏桿菌", "病原性大腸桿菌", "金黃色葡萄球菌",
                  "仙人掌桿菌", "肉毒桿菌", "其它", "化學物質", "天然毒", "諾羅病毒"]

    # Extract
    res = requests.get(URL, timeout=30)
    res.raise_for_status()
    raw_data = pd.DataFrame(res.json())

    # Transform
    data = raw_data.copy()
    # keep only single-year rows (exclude multi-year ranges like "70年至74年")
    data = data[~data["年度"].str.contains("至", na=False)]
    data["year"] = data["年度"].str.extract(r"(\d+)").astype(int) + 1911
    data = data[data["year"] >= data["year"].max() - 9]
    # convert cause columns to numeric
    for col in CAUSE_COLS:
        if col in data.columns:
            data[col] = pd.to_numeric(data[col], errors="coerce").fillna(0).astype(int)
    # melt cause columns into rows
    melted = data.melt(id_vars=["year"], value_vars=[c for c in CAUSE_COLS if c in data.columns],
                       var_name="cause", value_name="cases")
    melted["data_time"] = pd.to_datetime(melted["year"].astype(str) + "-01-01")
    ready_data = melted[["data_time", "year", "cause", "cases"]].sort_values(["year", "cause"]).reset_index(drop=True)

    # Load
    engine = create_engine(ready_data_db_uri)
    save_dataframe_to_postgresql(
        engine,
        data=ready_data,
        load_behavior=load_behavior,
        default_table=default_table,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="food_poisoning_cause")
dag.create_dag(etl_func=_food_poisoning_cause)
