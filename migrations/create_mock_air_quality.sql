-- Mock Data: 建立 moenv_air_quality 表並填入模擬資料
-- 目標資料庫：dashboard (postgres-data 容器)

BEGIN;

-- 1) 建立表結構 (參考 DAG D050502 定義)
CREATE TABLE IF NOT EXISTS public.moenv_air_quality (
    data_time               TIMESTAMP,
    site_id                 INTEGER,
    site_name               TEXT,
    county                  TEXT,
    status                  TEXT,
    aqi                     INTEGER,
    pollutant               TEXT,
    so2_ppb                 FLOAT,
    co_ppm                  FLOAT,
    o3_ppb                  FLOAT,
    o3_8hr_ppb              FLOAT,
    pm10_ug_m3              FLOAT,
    pm_2point5_ug_m3        FLOAT,
    no2_ppb                 FLOAT,
    nox_ppb                 FLOAT,
    no_ppb                  FLOAT,
    wind_speed_m_sec        FLOAT,
    wind_direction_degree   FLOAT,
    co_8hr_ppm              FLOAT,
    pm_2point5_avg_ug_m3    FLOAT,
    pm10_avg_ug_m3          FLOAT,
    so2_avg_ppb             FLOAT,
    lng                     FLOAT,
    lat                     FLOAT,
    wkb_geometry            GEOMETRY(Point, 4326)
);

-- 2) 清除舊資料 (如果有)
TRUNCATE TABLE public.moenv_air_quality;

-- 3) 插入模擬資料 (臺北與新北各站點)
INSERT INTO public.moenv_air_quality 
(site_name, county, aqi, status, pm_2point5_ug_m3, data_time, lng, lat, wkb_geometry)
VALUES
('萬華', '臺北市', 25, '良好', 8.0, NOW(), 121.507972, 25.046503, ST_SetSRID(ST_MakePoint(121.507972, 25.046503), 4326)),
('大同', '臺北市', 32, '良好', 10.0, NOW(), 121.513311, 25.063292, ST_SetSRID(ST_MakePoint(121.513311, 25.063292), 4326)),
('松山', '臺北市', 15, '良好', 4.0, NOW(), 121.578611, 25.050000, ST_SetSRID(ST_MakePoint(121.578611, 25.050000), 4326)),
('板橋', '新北市', 55, '普通', 16.0, NOW(), 121.457972, 25.011333, ST_SetSRID(ST_MakePoint(121.457972, 25.011333), 4326)),
('土城', '新北市', 42, '良好', 12.0, NOW(), 121.451861, 24.982528, ST_SetSRID(ST_MakePoint(121.451861, 24.982528), 4326)),
('三重', '新北市', 68, '普通', 22.0, NOW(), 121.493806, 25.072611, ST_SetSRID(ST_MakePoint(121.493806, 25.072611), 4326));

COMMIT;
