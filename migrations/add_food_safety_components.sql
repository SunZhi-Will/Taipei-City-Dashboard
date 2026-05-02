-- =============================================================
-- Migration: 食安月報儀表板 / Food Safety Dashboard
-- =============================================================
-- 新增組件：
--   taipei_imap_food      臺北市食品抽驗月報地圖（DonutChart + 月份動畫圓形圖）
--   ntpc_food_factory     新北市食品工廠清冊（MapLegend）
--   food_poisoning_trend  食品中毒月別趨勢（AnimatedColumnChart）
--   food_poisoning_cause  食品中毒病因物質（BarChart）
--   food_poisoning_food   食品中毒原因食品（BarChart）
--   food_poisoning_place  食品中毒攝食場所（BarChart）
--
-- 新增儀表板：food_safety_tpe（食品安全 - 臺北）
--
-- 前置條件：
--   GeoJSON 檔案已存在：
--     Taipei-City-Dashboard-FE/public/mapData/taipei_imap_food.geojson
--     Taipei-City-Dashboard-FE/public/mapData/ntpc_food_factory.geojson
--   dashboardmanager 資料庫已存在 components / component_charts /
--   component_maps / query_charts / dashboards 資料表
--
-- 執行方式：
--   psql -d dashboardmanager -f migrations/add_food_safety_components.sql
--
-- 回滾方式：
--   psql -d dashboardmanager -f migrations/rollback_food_safety_components.sql
-- =============================================================

BEGIN;

DO $mig$
DECLARE
    -- component_maps IDs
    v_food_map_id    BIGINT;
    v_ntpc_fac_id    BIGINT;
    v_max_map_id     BIGINT;

    -- components IDs
    v_taipei_food_cid   BIGINT;
    v_ntpc_factory_cid  BIGINT;
    v_fp_trend_cid      BIGINT;
    v_fp_cause_cid      BIGINT;
    v_fp_food_cid       BIGINT;
    v_fp_place_cid      BIGINT;

    -- dashboard
    v_dashboard_id   BIGINT;
    v_max_dash_id    BIGINT;

BEGIN

    -- ============================================================
    -- 0. 建立食物中毒統計資料表（若尚未存在）
    --    正式上線後由 Airflow DAG 填入真實資料，此處只建 schema
    -- ============================================================
    CREATE TABLE IF NOT EXISTS public.food_poisoning_trend (
        id          SERIAL       PRIMARY KEY,
        data_time   DATE         NOT NULL,
        year        INT          NOT NULL,
        month       INT          NOT NULL,
        cases       INT          NOT NULL DEFAULT 0,
        UNIQUE (year, month)
    );

    CREATE TABLE IF NOT EXISTS public.food_poisoning_cause (
        id          SERIAL       PRIMARY KEY,
        data_time   DATE         NOT NULL,
        year        INT          NOT NULL,
        cause       VARCHAR(64)  NOT NULL,
        cases       INT          NOT NULL DEFAULT 0,
        UNIQUE (year, cause)
    );

    CREATE TABLE IF NOT EXISTS public.food_poisoning_food (
        id          SERIAL       PRIMARY KEY,
        data_time   DATE         NOT NULL,
        year        INT          NOT NULL,
        food_type   VARCHAR(64)  NOT NULL,
        cases       INT          NOT NULL DEFAULT 0,
        UNIQUE (year, food_type)
    );

    CREATE TABLE IF NOT EXISTS public.food_poisoning_place (
        id          SERIAL       PRIMARY KEY,
        data_time   DATE         NOT NULL,
        year        INT          NOT NULL,
        place       VARCHAR(64)  NOT NULL,
        cases       INT          NOT NULL DEFAULT 0,
        UNIQUE (year, place)
    );

    RAISE NOTICE '0. Mock tables ensured';

    -- ============================================================
    -- 1. 插入 food_poisoning_trend Mock 資料（2016–2025）
    --    資料來源格式：衛福部食藥署 API（年-月別案件數）
    -- ============================================================
    INSERT INTO public.food_poisoning_trend (data_time, year, month, cases) VALUES
        -- 2016
        ('2016-01-01',2016,1,3),  ('2016-02-01',2016,2,2),  ('2016-03-01',2016,3,5),
        ('2016-04-01',2016,4,6),  ('2016-05-01',2016,5,8),  ('2016-06-01',2016,6,12),
        ('2016-07-01',2016,7,14), ('2016-08-01',2016,8,11), ('2016-09-01',2016,9,9),
        ('2016-10-01',2016,10,7), ('2016-11-01',2016,11,4), ('2016-12-01',2016,12,3),
        -- 2017
        ('2017-01-01',2017,1,4),  ('2017-02-01',2017,2,3),  ('2017-03-01',2017,3,6),
        ('2017-04-01',2017,4,7),  ('2017-05-01',2017,5,10), ('2017-06-01',2017,6,15),
        ('2017-07-01',2017,7,18), ('2017-08-01',2017,8,13), ('2017-09-01',2017,9,10),
        ('2017-10-01',2017,10,8), ('2017-11-01',2017,11,5), ('2017-12-01',2017,12,4),
        -- 2018
        ('2018-01-01',2018,1,3),  ('2018-02-01',2018,2,2),  ('2018-03-01',2018,3,5),
        ('2018-04-01',2018,4,8),  ('2018-05-01',2018,5,11), ('2018-06-01',2018,6,13),
        ('2018-07-01',2018,7,16), ('2018-08-01',2018,8,12), ('2018-09-01',2018,9,9),
        ('2018-10-01',2018,10,6), ('2018-11-01',2018,11,4), ('2018-12-01',2018,12,3),
        -- 2019
        ('2019-01-01',2019,1,5),  ('2019-02-01',2019,2,3),  ('2019-03-01',2019,3,7),
        ('2019-04-01',2019,4,9),  ('2019-05-01',2019,5,12), ('2019-06-01',2019,6,16),
        ('2019-07-01',2019,7,20), ('2019-08-01',2019,8,15), ('2019-09-01',2019,9,11),
        ('2019-10-01',2019,10,8), ('2019-11-01',2019,11,5), ('2019-12-01',2019,12,4),
        -- 2020（COVID 期間外食減少）
        ('2020-01-01',2020,1,4),  ('2020-02-01',2020,2,2),  ('2020-03-01',2020,3,3),
        ('2020-04-01',2020,4,3),  ('2020-05-01',2020,5,5),  ('2020-06-01',2020,6,8),
        ('2020-07-01',2020,7,10), ('2020-08-01',2020,8,9),  ('2020-09-01',2020,9,7),
        ('2020-10-01',2020,10,5), ('2020-11-01',2020,11,4), ('2020-12-01',2020,12,3),
        -- 2021
        ('2021-01-01',2021,1,3),  ('2021-02-01',2021,2,2),  ('2021-03-01',2021,3,4),
        ('2021-04-01',2021,4,2),  ('2021-05-01',2021,5,1),  ('2021-06-01',2021,6,3),
        ('2021-07-01',2021,7,5),  ('2021-08-01',2021,8,6),  ('2021-09-01',2021,9,4),
        ('2021-10-01',2021,10,3), ('2021-11-01',2021,11,2), ('2021-12-01',2021,12,2),
        -- 2022
        ('2022-01-01',2022,1,4),  ('2022-02-01',2022,2,3),  ('2022-03-01',2022,3,6),
        ('2022-04-01',2022,4,7),  ('2022-05-01',2022,5,9),  ('2022-06-01',2022,6,12),
        ('2022-07-01',2022,7,14), ('2022-08-01',2022,8,11), ('2022-09-01',2022,9,8),
        ('2022-10-01',2022,10,6), ('2022-11-01',2022,11,4), ('2022-12-01',2022,12,3),
        -- 2023
        ('2023-01-01',2023,1,5),  ('2023-02-01',2023,2,4),  ('2023-03-01',2023,3,8),
        ('2023-04-01',2023,4,9),  ('2023-05-01',2023,5,13), ('2023-06-01',2023,6,17),
        ('2023-07-01',2023,7,21), ('2023-08-01',2023,8,16), ('2023-09-01',2023,9,12),
        ('2023-10-01',2023,10,9), ('2023-11-01',2023,11,6), ('2023-12-01',2023,12,4),
        -- 2024
        ('2024-01-01',2024,1,6),  ('2024-02-01',2024,2,4),  ('2024-03-01',2024,3,9),
        ('2024-04-01',2024,4,10), ('2024-05-01',2024,5,14), ('2024-06-01',2024,6,18),
        ('2024-07-01',2024,7,22), ('2024-08-01',2024,8,17), ('2024-09-01',2024,9,13),
        ('2024-10-01',2024,10,10),('2024-11-01',2024,11,7), ('2024-12-01',2024,12,5),
        -- 2025（至 5 月，Airflow 跑後會被 replace）
        ('2025-01-01',2025,1,5),  ('2025-02-01',2025,2,3),  ('2025-03-01',2025,3,8),
        ('2025-04-01',2025,4,9),  ('2025-05-01',2025,5,12)
    ON CONFLICT (year, month) DO NOTHING;

    RAISE NOTICE '1. food_poisoning_trend mock data inserted';

    -- ============================================================
    -- 2. 插入 food_poisoning_cause Mock 資料（2023–2025）
    -- ============================================================
    INSERT INTO public.food_poisoning_cause (data_time, year, cause, cases) VALUES
        ('2023-01-01',2023,'腸炎弧菌',15),    ('2023-01-01',2023,'沙門氏桿菌',12),
        ('2023-01-01',2023,'病原性大腸桿菌',8),('2023-01-01',2023,'金黃色葡萄球菌',10),
        ('2023-01-01',2023,'仙人掌桿菌',6),   ('2023-01-01',2023,'化學物質',3),
        ('2023-01-01',2023,'天然毒',4),        ('2023-01-01',2023,'諾羅病毒',18),
        ('2023-01-01',2023,'肉毒桿菌',1),      ('2023-01-01',2023,'其它',7),
        ('2024-01-01',2024,'腸炎弧菌',17),    ('2024-01-01',2024,'沙門氏桿菌',14),
        ('2024-01-01',2024,'病原性大腸桿菌',9),('2024-01-01',2024,'金黃色葡萄球菌',11),
        ('2024-01-01',2024,'仙人掌桿菌',7),   ('2024-01-01',2024,'化學物質',4),
        ('2024-01-01',2024,'天然毒',5),        ('2024-01-01',2024,'諾羅病毒',20),
        ('2024-01-01',2024,'肉毒桿菌',2),      ('2024-01-01',2024,'其它',9),
        ('2025-01-01',2025,'腸炎弧菌',10),    ('2025-01-01',2025,'沙門氏桿菌',8),
        ('2025-01-01',2025,'病原性大腸桿菌',5),('2025-01-01',2025,'金黃色葡萄球菌',7),
        ('2025-01-01',2025,'仙人掌桿菌',3),   ('2025-01-01',2025,'化學物質',2),
        ('2025-01-01',2025,'天然毒',3),        ('2025-01-01',2025,'諾羅病毒',12),
        ('2025-01-01',2025,'肉毒桿菌',0),      ('2025-01-01',2025,'其它',5)
    ON CONFLICT (year, cause) DO NOTHING;

    RAISE NOTICE '2. food_poisoning_cause mock data inserted';

    -- ============================================================
    -- 3. 插入 food_poisoning_food Mock 資料（2024–2025）
    -- ============================================================
    INSERT INTO public.food_poisoning_food (data_time, year, food_type, cases) VALUES
        ('2024-01-01',2024,'複合調理食品',15), ('2024-01-01',2024,'水產品',12),
        ('2024-01-01',2024,'肉類',9),          ('2024-01-01',2024,'糕餅麵食',8),
        ('2024-01-01',2024,'其它',7),           ('2024-01-01',2024,'蔬菜類',4),
        ('2024-01-01',2024,'豆類製品',3),       ('2024-01-01',2024,'乳製品',2),
        ('2025-01-01',2025,'複合調理食品',10), ('2025-01-01',2025,'水產品',8),
        ('2025-01-01',2025,'肉類',6),           ('2025-01-01',2025,'糕餅麵食',5),
        ('2025-01-01',2025,'其它',4),           ('2025-01-01',2025,'蔬菜類',2),
        ('2025-01-01',2025,'豆類製品',2),       ('2025-01-01',2025,'乳製品',1)
    ON CONFLICT (year, food_type) DO NOTHING;

    RAISE NOTICE '3. food_poisoning_food mock data inserted';

    -- ============================================================
    -- 4. 插入 food_poisoning_place Mock 資料（2024–2025）
    -- ============================================================
    INSERT INTO public.food_poisoning_place (data_time, year, place, cases) VALUES
        ('2024-01-01',2024,'營業場所',20), ('2024-01-01',2024,'自宅',8),
        ('2024-01-01',2024,'其他',6),      ('2024-01-01',2024,'學校',5),
        ('2024-01-01',2024,'機關',3),      ('2024-01-01',2024,'醫療機構',1),
        ('2025-01-01',2025,'營業場所',14), ('2025-01-01',2025,'自宅',5),
        ('2025-01-01',2025,'其他',4),      ('2025-01-01',2025,'學校',3),
        ('2025-01-01',2025,'機關',2),      ('2025-01-01',2025,'醫療機構',1)
    ON CONFLICT (year, place) DO NOTHING;

    RAISE NOTICE '4. food_poisoning_place mock data inserted';

    -- ============================================================
    -- 5. 分配 component_maps（使用動態 ID，避免衝突）
    -- ============================================================

    -- taipei_imap_food（月份動畫圓點地圖，_animate 觸發 DonutChart 月份控制）
    SELECT id INTO v_food_map_id
    FROM public.component_maps WHERE index = 'taipei_imap_food' LIMIT 1;

    IF v_food_map_id IS NULL THEN
        SELECT COALESCE(MAX(id), 100) + 1 INTO v_max_map_id FROM public.component_maps;
        v_food_map_id := v_max_map_id;
        INSERT INTO public.component_maps
            (id, index, title, type, source, size, icon, paint, property)
        VALUES (
            v_food_map_id,
            'taipei_imap_food',
            '臺北市食品抽驗結果',
            'circle',
            'geojson',
            NULL, NULL,
            '{"circle-color":["match",["get","result"],"A1","#4CAF50","A2","#8BC34A","B1","#FF9800","#F44336"],"circle-radius":5,"circle-opacity":0.8}',
            '[{"key":"name","name":"店家名稱"},{"key":"district","name":"行政區"},{"key":"result","name":"抽驗結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'
        );
        RAISE NOTICE '  taipei_imap_food map inserted (id=%)', v_food_map_id;
    ELSE
        RAISE NOTICE '  taipei_imap_food map already exists (id=%)', v_food_map_id;
    END IF;

    -- ntpc_food_factory（靜態圓點地圖）
    SELECT id INTO v_ntpc_fac_id
    FROM public.component_maps WHERE index = 'ntpc_food_factory' LIMIT 1;

    IF v_ntpc_fac_id IS NULL THEN
        SELECT COALESCE(MAX(id), 100) + 1 INTO v_max_map_id FROM public.component_maps;
        v_ntpc_fac_id := v_max_map_id;
        INSERT INTO public.component_maps
            (id, index, title, type, source, size, icon, paint, property)
        VALUES (
            v_ntpc_fac_id,
            'ntpc_food_factory',
            '新北市食品工廠',
            'circle',
            'geojson',
            NULL, NULL,
            '{"circle-color":"#FF7043","circle-radius":5,"circle-opacity":0.75}',
            '[{"key":"name","name":"工廠名稱"},{"key":"address","name":"地址"},{"key":"reg_no","name":"登記號碼"}]'
        );
        RAISE NOTICE '  ntpc_food_factory map inserted (id=%)', v_ntpc_fac_id;
    ELSE
        RAISE NOTICE '  ntpc_food_factory map already exists (id=%)', v_ntpc_fac_id;
    END IF;

    RAISE NOTICE '5. component_maps done: food_map=%, ntpc_fac=%', v_food_map_id, v_ntpc_fac_id;

    -- ============================================================
    -- 6. 建立 components
    -- ============================================================
    SELECT id INTO v_taipei_food_cid  FROM public.components WHERE index = 'taipei_imap_food'      LIMIT 1;
    SELECT id INTO v_ntpc_factory_cid FROM public.components WHERE index = 'ntpc_food_factory'     LIMIT 1;
    SELECT id INTO v_fp_trend_cid     FROM public.components WHERE index = 'food_poisoning_trend'  LIMIT 1;
    SELECT id INTO v_fp_cause_cid     FROM public.components WHERE index = 'food_poisoning_cause'  LIMIT 1;
    SELECT id INTO v_fp_food_cid      FROM public.components WHERE index = 'food_poisoning_food'   LIMIT 1;
    SELECT id INTO v_fp_place_cid     FROM public.components WHERE index = 'food_poisoning_place'  LIMIT 1;

    IF v_taipei_food_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('taipei_imap_food','臺北市食品抽驗月報')
        RETURNING id INTO v_taipei_food_cid;
    END IF;
    IF v_ntpc_factory_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('ntpc_food_factory','新北市食品工廠清冊')
        RETURNING id INTO v_ntpc_factory_cid;
    END IF;
    IF v_fp_trend_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('food_poisoning_trend','食品中毒月別趨勢')
        RETURNING id INTO v_fp_trend_cid;
    END IF;
    IF v_fp_cause_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('food_poisoning_cause','食品中毒病因物質')
        RETURNING id INTO v_fp_cause_cid;
    END IF;
    IF v_fp_food_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('food_poisoning_food','食品中毒原因食品')
        RETURNING id INTO v_fp_food_cid;
    END IF;
    IF v_fp_place_cid IS NULL THEN
        INSERT INTO public.components (index, name) VALUES ('food_poisoning_place','食品中毒攝食場所')
        RETURNING id INTO v_fp_place_cid;
    END IF;

    RAISE NOTICE '6. components: taipei_food=%, ntpc_fac=%, trend=%, cause=%, food=%, place=%',
        v_taipei_food_cid, v_ntpc_factory_cid,
        v_fp_trend_cid, v_fp_cause_cid, v_fp_food_cid, v_fp_place_cid;

    -- ============================================================
    -- 7. component_charts（圖表顏色與類型設定）
    -- ============================================================
    INSERT INTO public.component_charts (index, color, types, unit) VALUES
        ('taipei_imap_food',
            '{#4CAF50,#FF9800,#F44336}',
            '{DonutChart}',
            NULL),
        ('ntpc_food_factory',
            '{#FF7043}',
            '{MapLegend}',
            NULL),
        ('food_poisoning_trend',
            '{#EF5350}',
            '{AnimatedColumnChart}',
            '件'),
        ('food_poisoning_cause',
            '{#EF5350,#FF7043,#FFA726,#FFCA28,#66BB6A,#26C6DA,#42A5F5,#7E57C2,#EC407A,#8D6E63}',
            '{BarChart}',
            '件'),
        ('food_poisoning_food',
            '{#FF7043,#FFA726,#FFCA28,#66BB6A,#26C6DA,#42A5F5,#7E57C2,#EC407A}',
            '{BarChart}',
            '件'),
        ('food_poisoning_place',
            '{#42A5F5,#66BB6A,#FFA726,#FF7043,#EC407A,#7E57C2,#26C6DA,#8D6E63}',
            '{BarChart}',
            '件')
    ON CONFLICT (index) DO UPDATE SET
        color = EXCLUDED.color,
        types = EXCLUDED.types,
        unit  = EXCLUDED.unit;

    RAISE NOTICE '7. component_charts upserted';

    -- ============================================================
    -- 8. query_charts（各組件的查詢設定）
    -- ============================================================

    -- taipei_imap_food（臺北）
    -- DonutChart 在地圖模式下從 GeoJSON → timeStore 讀取月份資料
    -- query_chart 提供靜態標籤供非地圖模式 fallback
    DELETE FROM public.query_charts WHERE index = 'taipei_imap_food' AND city = 'taipei';
        DELETE FROM public.query_charts WHERE index = 'ntpc_food_factory' AND city = 'metrotaipei';
        INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'taipei_imap_food',
        NULL,
        ARRAY[v_food_map_id],
        '{"mode":"byParam","byParam":{"xParam":"result"}}',
        'static', NULL, 1, 'month',
        '臺北市衛生局',
        '臺北市食品業者月別抽驗結果分布地圖，依月份動態顯示合格、複查與不合格比例。',
        '資料來源為臺北市政府衛生局食品藥物管理資訊系統（iMAPFood），收錄各食品業者每月抽驗結果（A1 合格/A2 合格/B1 正在複查/不符規定）。DonutChart 依月份動態呈現三類比例，搭配地圖圓點同步篩選。',
        '適用於追蹤臺北市食品安全現況、抽驗合格率趨勢，以及高風險區域識別。',
        '{https://imap.taipei.gov.tw/}',
        '{doit}',
        NOW(), NOW(),
        'two_d',
        $q$SELECT unnest(ARRAY['合格', '正在複查', '不合格']) AS x_axis, unnest(ARRAY[0, 0, 0]) AS data$q$,
        NULL,
        'taipei'
    );

    -- ntpc_food_factory（雙北）
    INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'ntpc_food_factory',
        NULL,
        ARRAY[v_ntpc_fac_id],
        '{}',
        'static', NULL, 0, NULL,
        '新北市政府衛生局',
        '新北市已登記食品製造工廠地理分布清冊，含廠商名稱、地址及座標。',
        '收錄新北市食品製造業工廠位址，含油脂、肉品、糕餅、飲料等類別，共約 1,232 筆（2023 年資料）。',
        '適用於了解新北市食品製造業地理分布，輔助食品安全稽查路線規劃。',
        '{https://data.ntpc.gov.tw/datasets/c51d5111-c300-44c9-b4f1-4b28b9929ca2}',
        '{ntpc}',
        NOW(), NOW(),
        'map_legend',
        $q$SELECT '新北市食品工廠' AS name, 'circle' AS type$q$,
        NULL,
        'metrotaipei'
    );

    -- food_poisoning_trend（臺北）
    -- AnimatedColumnChart：x_axis = 年份（YYYY-01-01），y_axis = 月份（01月～12月）
    -- 動畫按年逐步播放，每年顯示 12 個月別案件數長條
    DELETE FROM public.query_charts WHERE index = 'food_poisoning_trend' AND city = 'taipei';
        INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'food_poisoning_trend',
        NULL, '{}', '{}',
        'static', NULL, 1, 'year',
        '衛福部食品藥物管理署',
        '歷年食品中毒月別案件數動態趨勢（2016 年起），按年份逐步動畫呈現。',
        '資料來源為衛福部食藥署食品中毒統計（API），以月為單位呈現各年度案件數分布，可觀察夏季（7～9月）高峰及長期趨勢。',
        '適用於食安政策評估、季節性風險提醒及年際比較分析。',
        '{https://data.gov.tw/dataset/9835}',
        '{doit}',
        NOW(), NOW(),
        'time',
        $q$SELECT
  (year::text || '-01-01')::timestamptz AS x_axis,
  LPAD(month::text, 2, '0') || '月' AS y_axis,
  cases AS data
FROM public.food_poisoning_trend
ORDER BY year, month$q$,
        NULL,
        'taipei'
    );

    -- food_poisoning_cause（臺北）
    -- BarChart：顯示最近一年各病因物質案件數
    DELETE FROM public.query_charts WHERE index = 'food_poisoning_cause' AND city = 'taipei';
        INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'food_poisoning_cause',
        NULL, '{}', '{}',
        'static', NULL, 1, 'year',
        '衛福部食品藥物管理署',
        '最近一年食品中毒案件依病因物質分類統計（諾羅病毒、腸炎弧菌等）。',
        '依腸炎弧菌、沙門氏桿菌、諾羅病毒、化學物質、天然毒等病原分類，呈現近年案件件數排名。',
        '適用於了解主要食品中毒病因，輔助預防措施優先順序規劃與食安教育宣傳。',
        '{https://data.gov.tw/dataset/9836}',
        '{doit}',
        NOW(), NOW(),
        'two_d',
        $q$SELECT cause AS x_axis, cases AS data
FROM public.food_poisoning_cause
WHERE year = (SELECT max(year) FROM public.food_poisoning_cause)
ORDER BY cases DESC$q$,
        NULL,
        'taipei'
    );

    -- food_poisoning_food（臺北）
    DELETE FROM public.query_charts WHERE index = 'food_poisoning_food' AND city = 'taipei';
        INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'food_poisoning_food',
        NULL, '{}', '{}',
        'static', NULL, 1, 'year',
        '衛福部食品藥物管理署',
        '最近一年食品中毒案件依原因食品分類統計（水產品、複合調理食品等）。',
        '依水產品、肉類、糕餅麵食、複合調理食品等食品類別呈現近年案件件數，排名越高代表風險越高。',
        '適用於了解高風險食品類型，輔助食安稽查重點設定及消費者飲食安全教育。',
        '{https://data.gov.tw/dataset/9837}',
        '{doit}',
        NOW(), NOW(),
        'two_d',
        $q$SELECT food_type AS x_axis, cases AS data
FROM public.food_poisoning_food
WHERE year = (SELECT max(year) FROM public.food_poisoning_food)
ORDER BY cases DESC$q$,
        NULL,
        'taipei'
    );

    -- food_poisoning_place（臺北）
    DELETE FROM public.query_charts WHERE index = 'food_poisoning_place' AND city = 'taipei';
        INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'food_poisoning_place',
        NULL, '{}', '{}',
        'static', NULL, 1, 'year',
        '衛福部食品藥物管理署',
        '最近一年食品中毒案件依攝食場所分類統計（營業場所、自宅、學校等）。',
        '依自宅、營業場所、學校、機關等場所分類，呈現近年案件件數排名，反映不同場所的食安管理落差。',
        '適用於了解高風險攝食場所，輔助衛生稽查重點安排及食安宣導對象選擇。',
        '{https://data.gov.tw/dataset/9838}',
        '{doit}',
        NOW(), NOW(),
        'two_d',
        $q$SELECT place AS x_axis, cases AS data
FROM public.food_poisoning_place
WHERE year = (SELECT max(year) FROM public.food_poisoning_place)
ORDER BY cases DESC$q$,
        NULL,
        'taipei'
    );

    RAISE NOTICE '8. query_charts upserted';

    -- ============================================================
    -- 9. 建立 food_safety_tpe 儀表板（冪等）
    -- ============================================================
    IF NOT EXISTS (SELECT 1 FROM public.dashboards WHERE index = 'food_safety_tpe') THEN
        SELECT COALESCE(MAX(id), 300) + 1 INTO v_max_dash_id
        FROM public.dashboards WHERE id < 900;

        INSERT INTO public.dashboards
            (id, index, name, components, icon, updated_at, created_at)
        VALUES (
            v_max_dash_id,
            'food_safety_tpe',
            '食品安全',
            ARRAY[
                v_taipei_food_cid,
                v_fp_trend_cid,
                v_fp_cause_cid,
                v_fp_food_cid,
                v_fp_place_cid
            ],
            'food_bank',
            NOW(), NOW()
        );
        RAISE NOTICE '  food_safety_tpe dashboard created (id=%)', v_max_dash_id;
    ELSE
        UPDATE public.dashboards
        SET
            components = ARRAY[
                v_taipei_food_cid,
                v_fp_trend_cid,
                v_fp_cause_cid,
                v_fp_food_cid,
                v_fp_place_cid
            ],
            updated_at = NOW()
        WHERE index = 'food_safety_tpe';
        RAISE NOTICE '  food_safety_tpe dashboard updated';
    END IF;

    -- 將 ntpc_food_factory 加入 map-layers-metrotaipei（若尚未存在）
    UPDATE public.dashboards
    SET
        components = array_append(components, v_ntpc_factory_cid::integer),
        updated_at = NOW()
    WHERE index = 'map-layers-metrotaipei'
      AND NOT (components @> ARRAY[v_ntpc_factory_cid::integer]);

    RAISE NOTICE '9. Dashboards updated';
    RAISE NOTICE '=== Migration add_food_safety_components completed ===';

END $mig$;

COMMIT;
