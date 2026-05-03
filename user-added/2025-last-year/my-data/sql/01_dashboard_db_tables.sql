-- ===========================================================
-- 黑客松功能整合 - Dashboard DB 資料表建立
-- 適用 DB: dashboard (container: postgres-data)
-- 執行: docker exec -i postgres-data psql -U postgres -d dashboard < 01_dashboard_db_tables.sql
-- ===========================================================

-- 1. AED 自動體外除顫器 (台北市)
CREATE TABLE IF NOT EXISTS public.aed_tpe (
    name          text NOT NULL,
    address       text,
    district      text,
    latitude      double precision,
    longitude     double precision,
    category      text,
    type          text,
    location_desc text,
    _ctime        timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime        timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.aed_tpe IS '台北市 AED 自動體外除顫器分布';

-- 2. 原住民族人口 - 行政區別 (台北市)
CREATE TABLE IF NOT EXISTS public.indigenous_by_district_tpe (
    year                 integer NOT NULL,
    month                integer NOT NULL,
    district             text    NOT NULL,
    gender               text    NOT NULL,
    total                integer,
    population_plains    integer,
    population_mountains integer,
    _ctime               timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime               timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.indigenous_by_district_tpe IS '台北市原住民族人口 - 行政區別';
CREATE INDEX IF NOT EXISTS idx_indigenous_district_year ON public.indigenous_by_district_tpe(year, month);

-- 3. 原住民族人口 - 族別 (台北市)
CREATE TABLE IF NOT EXISTS public.indigenous_by_group_tpe (
    year                  integer NOT NULL,
    month                 integer NOT NULL,
    gender                text    NOT NULL,
    total                 integer,
    population_amis       integer,
    population_atayal     integer,
    population_paiwan     integer,
    population_bunun      integer,
    population_rukai      integer,
    population_pinan      integer,
    population_tsou       integer,
    population_saisiyat   integer,
    population_yami       integer,
    population_thao       integer,
    population_kavalan    integer,
    population_truku      integer,
    population_sakizaya   integer,
    population_seediq     integer,
    population_laaruwa    integer,
    population_kanakanavu integer,
    unreported            integer,
    _ctime                timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime                timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.indigenous_by_group_tpe IS '台北市原住民族人口 - 族別';
CREATE INDEX IF NOT EXISTS idx_indigenous_group_year ON public.indigenous_by_group_tpe(year, month);

-- 4. 受聘僱移工 (台北市)
CREATE TABLE IF NOT EXISTS public.migrant_workers_employed_tpe (
    year        integer NOT NULL,
    month       integer NOT NULL,
    nationality text    NOT NULL,
    job_type    text    NOT NULL,
    count       integer,
    _ctime      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime      timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.migrant_workers_employed_tpe IS '台北市受聘僱移工統計';
CREATE INDEX IF NOT EXISTS idx_migrant_tpe_year ON public.migrant_workers_employed_tpe(year, month);

-- 5. 受聘僱移工 (新北市)
CREATE TABLE IF NOT EXISTS public.migrant_workers_employed_ntpc (
    year        integer NOT NULL,
    month       integer NOT NULL,
    nationality text    NOT NULL,
    job_type    text    NOT NULL,
    count       integer,
    _ctime      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime      timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.migrant_workers_employed_ntpc IS '新北市受聘僱移工統計';
CREATE INDEX IF NOT EXISTS idx_migrant_ntpc_year ON public.migrant_workers_employed_ntpc(year, month);

-- 6. 長照ABC據點 (台北市，含部分新北資料)
CREATE TABLE IF NOT EXISTS public.long_term_care_abc_tpe (
    name      text NOT NULL,
    code      text,
    type      text,
    city      text,
    district  text,
    address   text,
    longitude double precision,
    latitude  double precision,
    o_abc     text,
    services  text,
    _ctime    timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    _mtime    timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.long_term_care_abc_tpe IS '長照ABC服務型據點 (台北市)';
CREATE INDEX IF NOT EXISTS idx_ltc_district ON public.long_term_care_abc_tpe(district);
CREATE INDEX IF NOT EXISTS idx_ltc_o_abc ON public.long_term_care_abc_tpe(o_abc);
