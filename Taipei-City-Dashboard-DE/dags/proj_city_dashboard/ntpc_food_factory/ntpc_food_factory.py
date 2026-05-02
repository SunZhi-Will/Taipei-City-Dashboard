from airflow import DAG
from operators.common_pipeline import CommonDag


def _ntpc_food_factory(**kwargs):
    import pandas as pd
    import requests
    from sqlalchemy import create_engine
    from utils.load_stage import (
        save_geodataframe_to_postgresql,
        update_lasttime_in_data_to_dataset_info,
    )
    from utils.transform_geometry import add_point_wkbgeometry_column_to_df

    # Config
    ready_data_db_uri = kwargs.get("ready_data_db_uri")
    dag_infos = kwargs.get("dag_infos")
    dag_id = dag_infos.get("dag_id")
    load_behavior = dag_infos.get("load_behavior")
    default_table = dag_infos.get("ready_data_default_table")
    URL = "https://data.ntpc.gov.tw/api/datasets/c51d5111-c300-44c9-b4f1-4b28b9929ca2/json"
    FROM_CRS = 4326
    GEOMETRY_TYPE = "Point"

    # Extract — paginate until empty batch
    all_records = []
    page, size = 0, 1000
    while True:
        res = requests.get(URL, params={"page": page, "size": size}, timeout=30)
        res.raise_for_status()
        batch = res.json()
        if not batch:
            break
        all_records.extend(batch)
        if len(batch) < size:
            break
        page += 1
    raw_data = pd.DataFrame(all_records)

    # Transform
    data = raw_data.copy()
    data["lng"] = pd.to_numeric(data["wgs84ax"], errors="coerce")
    data["lat"] = pd.to_numeric(data["wgs84ay"], errors="coerce")
    data = data.dropna(subset=["lng", "lat"])
    data = data[data["lng"] != 0]
    data["data_time"] = pd.to_datetime(data["date"], format="%Y%m%d", errors="coerce")
    data["data_time"] = data["data_time"].fillna(pd.Timestamp("2023-07-31"))
    data = data.rename(columns={"organizer": "name", "no": "reg_no", "tax_id_number": "tax_id"})
    data["address"] = data["address"].astype(str)

    gdata = add_point_wkbgeometry_column_to_df(data, data["lng"], data["lat"], from_crs=FROM_CRS)
    gdata = gdata.drop(columns="geometry")

    ready_data = gdata[["data_time", "name", "reg_no", "tax_id", "address", "lat", "lng", "wkb_geometry"]]

    # Load
    engine = create_engine(ready_data_db_uri)
    save_geodataframe_to_postgresql(
        engine,
        gdata=ready_data,
        load_behavior=load_behavior,
        default_table=default_table,
        geometry_type=GEOMETRY_TYPE,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, ready_data["data_time"].max())


dag = CommonDag(proj_folder="proj_city_dashboard", dag_folder="ntpc_food_factory")
dag.create_dag(etl_func=_ntpc_food_factory)
