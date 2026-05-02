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
-- ⚠️  重要：雙資料庫架構
--   本檔案需分兩步驟執行：
--   Step A（dashboardmanager）— 組件 metadata 與儀表板設定：
--     psql -d dashboardmanager -f migrations/add_food_safety_components.sql
--   Step B（dashboard）— 圖表資料表 + mock 資料（見 deploy_to_docker.sh）：
--     psql -d dashboard -f migrations/add_food_safety_data_tables.sql
--
--   或使用 run_all.sh 一次完成兩步。
--
-- 前置條件：
--   GeoJSON 檔案已存在：
--     Taipei-City-Dashboard-FE/public/mapData/taipei_imap_food.geojson
--     Taipei-City-Dashboard-FE/public/mapData/ntpc_food_factory.geojson
--   dashboardmanager 資料庫已存在 components / component_charts /
--   component_maps / query_charts / dashboards 資料表
--
-- 執行方式（metadata only）：
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
    v_taipei_dashboard_id BIGINT;
    v_map_layers_taipei_id BIGINT;
    v_map_layers_metrotaipei_id BIGINT;
    v_max_dash_id    BIGINT;

BEGIN

    -- ============================================================
    -- 0–4. 資料表建立與 mock 資料插入
    --      ⚠️  已移至 add_food_safety_data_tables.sql
    --          需於 postgres-data/dashboard 執行，本檔不含此步驟
    -- ============================================================
    RAISE NOTICE '0-4. Skipped (run add_food_safety_data_tables.sql against postgres-data/dashboard)';

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
    -- 9. 確保 map-layers-taipei / map-layers-metrotaipei 存在
    -- ============================================================
    SELECT id INTO v_map_layers_taipei_id
    FROM public.dashboards
    WHERE index = 'map-layers-taipei'
    LIMIT 1;

    IF v_map_layers_taipei_id IS NULL THEN
        SELECT COALESCE(MAX(id), 300) + 1 INTO v_max_dash_id
        FROM public.dashboards WHERE id < 900;

        v_map_layers_taipei_id := v_max_dash_id;
        INSERT INTO public.dashboards
            (id, index, name, components, icon, updated_at, created_at)
        VALUES (
            v_map_layers_taipei_id,
            'map-layers-taipei',
            '圖資資訊',
            ARRAY[]::integer[],
            'public',
            NOW(), NOW()
        );
    END IF;

    INSERT INTO public.dashboard_groups (dashboard_id, group_id)
    VALUES (v_map_layers_taipei_id, 2)
    ON CONFLICT DO NOTHING;

    SELECT id INTO v_map_layers_metrotaipei_id
    FROM public.dashboards
    WHERE index = 'map-layers-metrotaipei'
    LIMIT 1;

    IF v_map_layers_metrotaipei_id IS NULL THEN
        SELECT COALESCE(MAX(id), 300) + 1 INTO v_max_dash_id
        FROM public.dashboards WHERE id < 900;

        v_map_layers_metrotaipei_id := v_max_dash_id;
        INSERT INTO public.dashboards
            (id, index, name, components, icon, updated_at, created_at)
        VALUES (
            v_map_layers_metrotaipei_id,
            'map-layers-metrotaipei',
            '圖資資訊',
            ARRAY[]::integer[],
            'public',
            NOW(), NOW()
        );
    END IF;

    INSERT INTO public.dashboard_groups (dashboard_id, group_id)
    VALUES (v_map_layers_metrotaipei_id, 3)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 9. 建立 food_safety_taipei 儀表板（冪等，僅 taipei）
    -- ============================================================
    IF NOT EXISTS (SELECT 1 FROM public.dashboards WHERE index = 'food_safety_taipei') THEN
        SELECT COALESCE(MAX(id), 300) + 1 INTO v_max_dash_id
        FROM public.dashboards WHERE id < 900;

        INSERT INTO public.dashboards
            (id, index, name, components, icon, updated_at, created_at)
        VALUES (
            v_max_dash_id,
            'food_safety_taipei',
            '臺北食品安全',
            ARRAY[
                v_taipei_food_cid,
                v_fp_trend_cid,
                v_fp_cause_cid,
                v_fp_food_cid,
                v_fp_place_cid
            ],
            'health_and_safety',
            NOW(), NOW()
        );
        RAISE NOTICE '  food_safety_taipei dashboard created (id=%)', v_max_dash_id;
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
        WHERE index = 'food_safety_taipei';
        RAISE NOTICE '  food_safety_taipei dashboard updated';
    END IF;

    -- ============================================================
    -- 10. 建立 food_safety_tpe 儀表板（冪等，僅 metrotaipei）
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
                v_ntpc_factory_cid,
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
                v_ntpc_factory_cid,
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

        -- food_safety_taipei 只加入 taipei(2) 群組
        SELECT id INTO v_taipei_dashboard_id
        FROM public.dashboards
        WHERE index = 'food_safety_taipei';

        DELETE FROM public.dashboard_groups
        WHERE dashboard_id = v_taipei_dashboard_id
            AND group_id IN (2, 3);

        INSERT INTO public.dashboard_groups (dashboard_id, group_id)
        VALUES (v_taipei_dashboard_id, 2)
        ON CONFLICT DO NOTHING;

        -- food_safety_tpe 只加入 metrotaipei(3) 群組
        DELETE FROM public.dashboard_groups
        WHERE dashboard_id IN (
                SELECT id FROM public.dashboards WHERE index = 'food_safety_tpe'
        )
            AND group_id IN (2, 3);

    INSERT INTO public.dashboard_groups (dashboard_id, group_id)
        SELECT id, 3 FROM public.dashboards WHERE index = 'food_safety_tpe'
    ON CONFLICT DO NOTHING;

        RAISE NOTICE '10. Dashboards updated';
    RAISE NOTICE '=== Migration add_food_safety_components completed ===';

END $mig$;

COMMIT;
