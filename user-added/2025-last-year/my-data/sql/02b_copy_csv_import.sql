-- ===========================================================
-- 黑客松功能整合 - 批次 CSV 匯入腳本
-- 前置條件: CSV 已透過 docker cp 複製到容器 /tmp/ 目錄
-- 適用 DB: dashboard (container: postgres-data)
-- ===========================================================

-- ── AED 台北市 ──────────────────────────────────────────────
-- CSV columns: name,address,district_code,latitude,longitude,category,type,location_desc,district

TRUNCATE TABLE public.aed_tpe;

CREATE TEMP TABLE tmp_aed_raw (
    name          text,
    address       text,
    district_code text,
    latitude      double precision,
    longitude     double precision,
    category      text,
    type          text,
    location_desc text,
    district      text
) ON COMMIT DROP;

COPY tmp_aed_raw
    (name, address, district_code, latitude, longitude, category, type, location_desc, district)
FROM '/tmp/aed_tpe.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

INSERT INTO public.aed_tpe
    (name, address, district, latitude, longitude, category, type, location_desc)
SELECT name, address, district, latitude, longitude, category, type, location_desc
FROM tmp_aed_raw;

DROP TABLE tmp_aed_raw;

SELECT 'aed_tpe' AS table_name, COUNT(*) AS rows FROM public.aed_tpe;

-- ── 原住民族人口 - 行政區別 ────────────────────────────────
-- CSV columns: year,month,district,gender,total,population_plains,population_mountains

TRUNCATE TABLE public.indigenous_by_district_tpe;

COPY public.indigenous_by_district_tpe
    (year, month, district, gender, total, population_plains, population_mountains)
FROM '/tmp/indigenous_by_district_tpe.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

SELECT 'indigenous_by_district_tpe' AS table_name, COUNT(*) AS rows FROM public.indigenous_by_district_tpe;

-- ── 原住民族人口 - 族別 ────────────────────────────────────
-- CSV columns: year,month,gender,total,population_amis,...,unreported

TRUNCATE TABLE public.indigenous_by_group_tpe;

COPY public.indigenous_by_group_tpe
    (year, month, gender, total,
     population_amis, population_atayal, population_paiwan, population_bunun,
     population_rukai, population_pinan, population_tsou, population_saisiyat,
     population_yami, population_thao, population_kavalan, population_truku,
     population_sakizaya, population_seediq, population_laaruwa, population_kanakanavu,
     unreported)
FROM '/tmp/indigenous_by_group_tpe.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

SELECT 'indigenous_by_group_tpe' AS table_name, COUNT(*) AS rows FROM public.indigenous_by_group_tpe;

-- ── 受聘僱移工 台北市 ──────────────────────────────────────
-- CSV columns: year,month,nationality,job_type,count

TRUNCATE TABLE public.migrant_workers_employed_tpe;

COPY public.migrant_workers_employed_tpe
    (year, month, nationality, job_type, count)
FROM '/tmp/migrant_workers_employed_tpe.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

SELECT 'migrant_workers_employed_tpe' AS table_name, COUNT(*) AS rows FROM public.migrant_workers_employed_tpe;

-- ── 受聘僱移工 新北市 ──────────────────────────────────────
-- CSV columns: year,month,nationality,job_type,count

TRUNCATE TABLE public.migrant_workers_employed_ntpc;

COPY public.migrant_workers_employed_ntpc
    (year, month, nationality, job_type, count)
FROM '/tmp/migrant_workers_employed_ntpc.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

SELECT 'migrant_workers_employed_ntpc' AS table_name, COUNT(*) AS rows FROM public.migrant_workers_employed_ntpc;

-- ── 長照ABC據點 台北市 ─────────────────────────────────────
-- CSV columns: 機構名稱,機構代碼,機構種類,縣市,區,地址全址,經度,緯度,O_ABC,特約服務項目

TRUNCATE TABLE public.long_term_care_abc_tpe;

CREATE TEMP TABLE tmp_ltc_raw (
    name      text,
    code      text,
    type      text,
    city      text,
    district  text,
    address   text,
    longitude double precision,
    latitude  double precision,
    o_abc     text,
    services  text
) ON COMMIT DROP;

COPY tmp_ltc_raw (name, code, type, city, district, address, longitude, latitude, o_abc, services)
FROM '/tmp/long_term_care_abc_tpe.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

INSERT INTO public.long_term_care_abc_tpe
    (name, code, type, city, district, address, longitude, latitude, o_abc, services)
SELECT name, code, type, city, district, address, longitude, latitude, o_abc, services
FROM tmp_ltc_raw;

DROP TABLE tmp_ltc_raw;

SELECT 'long_term_care_abc_tpe' AS table_name, COUNT(*) AS rows FROM public.long_term_care_abc_tpe;
