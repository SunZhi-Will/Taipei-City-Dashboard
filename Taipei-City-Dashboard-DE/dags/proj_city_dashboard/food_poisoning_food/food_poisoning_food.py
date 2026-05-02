from airflow import DAG
from operators.common_pipeline import CommonDag


def _food_poisoning_food(**kwargs):
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
    URL = "https://data.fda.gov.tw/data/opendata/export/116/json"
    FOOD_COLS = ["水產品", "水產加工品", "肉類及其加工品", "蛋類", "乳類",
                 "穀類", "蔬果類", "糕餅糖果類", "複合調理食品", "其他"]

    # Extract
    res = requests.get(URL, timeout=30)
    res.raise_for_status()
    raw_data = pd.DataFrame(res.json())

    # Transform
    data = raw_data.copy()
    data = data[~data["年度"].str.contains("至", na=False)]
    data["year"] = data["年度"].str.extract(r"(\d+)").astype(int) + 1911
    data = data[data["year"] >= data["year"].max() - 9]
    for col in FOOD_COLS:
        if col in data.columns:
            data[col] = pd.to_numeric(data[col], errors="coerce").fillna(0).astype(int)
    melted = data.melt(id_vars=["year"], value_vars=[c for c in FOOD_COLS if c in data.columns],
                       var_name="food_type", value_name="cases")
    melted["data_time"] = pd.to_datetime(melted["year"].astype(str) + "-01-01")
    ready_data = melted[["data_time", "year", "food_type", "cases"]].sort_values(["year", "food_type"]).reset_index(drop=True)

    # Load
    engine = create_engine(ready_data_db_uri)
    save_dataframe_to_postgresql(
        engine,
        data=ready_data,
        load_behavior=load_behavior,
        default_table=default_table,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="food_poisoning_food")
dag.create_dag(etl_func=_food_poisoning_food)
