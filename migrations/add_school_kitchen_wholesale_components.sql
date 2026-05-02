-- =============================================================
-- Migration: 食安地圖補完 / Food Safety Map Completion
-- =============================================================
-- 新增組件：
--   school_kitchen_imap          臺北市學校廚房衛生稽查地圖（DonutChart）
--   wholesale_pesticide_inspection  雙北果菜批發市場農藥殘留地圖（DonutChart）
--
-- 修正：
--   food_safety_tpe dashboard 補入 ntpc_food_factory（id 已存在）
--
-- 前置條件：
--   GeoJSON 檔案已存在：
--     Taipei-City-Dashboard-FE/public/mapData/school_kitchen_imap.geojson
--     Taipei-City-Dashboard-FE/public/mapData/wholesale_pesticide_inspection.geojson
--   add_food_safety_components.sql 已執行（food_safety_tpe dashboard 存在）
--
-- 執行方式：
--   psql -d dashboardmanager -f migrations/add_school_kitchen_wholesale_components.sql
--
-- 回滾方式：
--   psql -d dashboardmanager -f migrations/rollback_school_kitchen_wholesale_components.sql
-- =============================================================

BEGIN;

DO $mig$
DECLARE
    -- component_maps IDs
    v_kitchen_map_id    BIGINT;
    v_pesticide_map_id  BIGINT;
    v_max_map_id        BIGINT;

    -- components IDs
    v_kitchen_cid       BIGINT;
    v_pesticide_cid     BIGINT;
    v_ntpc_fac_cid      BIGINT;

    -- dashboard
    v_food_dash_id      BIGINT;

BEGIN

    -- ============================================================
    -- 1. component_maps（動態 ID 避免衝突）
    -- ============================================================

    -- school_kitchen_imap
    SELECT id INTO v_kitchen_map_id
    FROM public.component_maps WHERE index = 'school_kitchen_imap' LIMIT 1;

    IF v_kitchen_map_id IS NULL THEN
        SELECT COALESCE(MAX(id), 100) + 1 INTO v_max_map_id FROM public.component_maps;
        v_kitchen_map_id := v_max_map_id;
        INSERT INTO public.component_maps
            (id, index, title, type, source, size, icon, paint, property)
        VALUES (
            v_kitchen_map_id,
            'school_kitchen_imap',
            '臺北市學校廚房稽查',
            'circle',
            'geojson',
            NULL, NULL,
            '{"circle-color":["match",["get","result"],"A1","#4CAF50","A2","#8BC34A","B1","#FF9800","#F44336"],"circle-radius":6,"circle-opacity":0.85}',
            '[{"key":"name","name":"學校名稱"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"result","name":"稽查結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'
        );
        RAISE NOTICE '1a. school_kitchen_imap map inserted (id=%)', v_kitchen_map_id;
    ELSE
        RAISE NOTICE '1a. school_kitchen_imap map already exists (id=%)', v_kitchen_map_id;
    END IF;

    -- wholesale_pesticide_inspection
    SELECT id INTO v_pesticide_map_id
    FROM public.component_maps WHERE index = 'wholesale_pesticide_inspection' LIMIT 1;

    IF v_pesticide_map_id IS NULL THEN
        SELECT COALESCE(MAX(id), 100) + 1 INTO v_max_map_id FROM public.component_maps;
        v_pesticide_map_id := v_max_map_id;
        INSERT INTO public.component_maps
            (id, index, title, type, source, size, icon, paint, property)
        VALUES (
            v_pesticide_map_id,
            'wholesale_pesticide_inspection',
            '批發市場農藥殘留檢驗',
            'circle',
            'geojson',
            NULL, NULL,
            '{"circle-color":["match",["get","result"],"合格","#4CAF50","#F44336"],"circle-radius":6,"circle-opacity":0.85}',
            '[{"key":"market","name":"市場"},{"key":"product_name","name":"品項"},{"key":"result","name":"檢驗結果"},{"key":"pesticides","name":"不合格農藥"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'
        );
        RAISE NOTICE '1b. wholesale_pesticide_inspection map inserted (id=%)', v_pesticide_map_id;
    ELSE
        RAISE NOTICE '1b. wholesale_pesticide_inspection map already exists (id=%)', v_pesticide_map_id;
    END IF;

    RAISE NOTICE '1. component_maps done: kitchen=%, pesticide=%', v_kitchen_map_id, v_pesticide_map_id;

    -- ============================================================
    -- 2. components
    -- ============================================================
    SELECT id INTO v_kitchen_cid
    FROM public.components WHERE index = 'school_kitchen_imap' LIMIT 1;
    IF v_kitchen_cid IS NULL THEN
        INSERT INTO public.components (index, name)
        VALUES ('school_kitchen_imap', '臺北市學校廚房稽查')
        RETURNING id INTO v_kitchen_cid;
    END IF;

    SELECT id INTO v_pesticide_cid
    FROM public.components WHERE index = 'wholesale_pesticide_inspection' LIMIT 1;
    IF v_pesticide_cid IS NULL THEN
        INSERT INTO public.components (index, name)
        VALUES ('wholesale_pesticide_inspection', '雙北批發市場農藥殘留')
        RETURNING id INTO v_pesticide_cid;
    END IF;

    -- ntpc_food_factory (已存在，只取 id)
    SELECT id INTO v_ntpc_fac_cid
    FROM public.components WHERE index = 'ntpc_food_factory' LIMIT 1;

    RAISE NOTICE '2. components: kitchen=%, pesticide=%, ntpc_fac=%',
        v_kitchen_cid, v_pesticide_cid, v_ntpc_fac_cid;

    -- ============================================================
    -- 3. component_charts
    -- ============================================================
    INSERT INTO public.component_charts (index, color, types, unit) VALUES
        ('school_kitchen_imap',
            '{#4CAF50,#8BC34A,#FF9800,#F44336}',
            '{DonutChart}',
            NULL),
        ('wholesale_pesticide_inspection',
            '{#4CAF50,#F44336}',
            '{DonutChart,BarChart}',
            NULL)
    ON CONFLICT (index) DO UPDATE SET
        color = EXCLUDED.color,
        types = EXCLUDED.types,
        unit  = EXCLUDED.unit;

    RAISE NOTICE '3. component_charts upserted';

    -- ============================================================
    -- 4. query_charts
    -- ============================================================

    -- school_kitchen_imap（臺北）
    -- 目前來源為靜態 GeoJSON，dashboard DB 無對應資料表，chart query 需保存既有統計值
    DELETE FROM public.query_charts
    WHERE index = 'school_kitchen_imap' AND city = 'taipei';

    INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    VALUES (
        'school_kitchen_imap',
        NULL,
        ARRAY[v_kitchen_map_id],
        '{"mode":"byParam","byParam":{"xParam":"result"}}',
        'static', NULL, 1, 'month',
        '臺北市衛生局 iMAPFood',
        '臺北市各級學校廚房衛生稽查結果地圖，依月份動態顯示合格與不合格比例。',
        '資料來源為臺北市衛生局 iMAPFood 食品業者稽查系統，篩選機關類別（學校）之廚房稽查紀錄，共收錄全市 12 行政區，結果分為 A1 優良、A2 合格、B1 限期改善、不符規定四等級。',
        '適用於監控各學區學校廚房衛生狀況，輔助家長及教育單位掌握校園食安風險。',
        '{https://imap.taipei.gov.tw/}',
        '{doit}',
        NOW(), NOW(),
        'two_d',
        $q$SELECT unnest(ARRAY['A1優良','A2合格','B1限改','不符規定']) AS x_axis,
               unnest(ARRAY[40,12,1,1])::float AS data$q$,
        NULL,
        'taipei'
    );

    -- wholesale_pesticide_inspection (taipei & metrotaipei)
    DELETE FROM public.query_charts
    WHERE index = 'wholesale_pesticide_inspection' AND city IN ('taipei', 'metrotaipei');

    INSERT INTO public.query_charts
        (index, history_config, map_config_ids, map_filter,
         time_from, time_to, update_freq, update_freq_unit,
         source, short_desc, long_desc, use_case,
         links, contributors, created_at, updated_at,
         query_type, query_chart, query_history, city)
    SELECT
        'wholesale_pesticide_inspection',
        NULL,
        ARRAY[v_pesticide_map_id],
        '{"mode":"byParam","byParam":{"xParam":"result"}}',
        'static', NULL, 1, 'day',
        CASE WHEN city_name = 'taipei' THEN '臺北農產運銷公司' ELSE '臺北農產運銷公司 + 新北市果菜運銷公司' END,
        CASE WHEN city_name = 'taipei' THEN '臺北批發市場農藥殘留檢驗結果。' ELSE '雙北批發市場農藥殘留檢驗結果。' END,
        '統計批發市場資料，將非「合格」結果統一視為不合格。',
        '適用於檢視批發市場蔬果農藥殘留風險。',
        CASE WHEN city_name = 'taipei' THEN '{https://www.tapmc.com.tw/}'::text[] ELSE '{https://www.tapmc.com.tw/,https://www.ntpm.com.tw/}'::text[] END,
        '{doit}',
        NOW(), NOW(),
        'two_d',
        CASE WHEN city_name = 'taipei' 
               THEN $q$SELECT CASE WHEN result = '合格' THEN '合格' ELSE '不合格' END AS x_axis, COUNT(*)::float AS data FROM public.wholesale_pesticide_inspection WHERE market IN ('第一批發市場', '第二批發市場') GROUP BY 1 ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)$q$
               ELSE $q$SELECT CASE WHEN result = '合格' THEN '合格' ELSE '不合格' END AS x_axis, COUNT(*)::float AS data FROM public.wholesale_pesticide_inspection GROUP BY 1 ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)$q$
        END,
        NULL,
        city_name
    FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

    RAISE NOTICE '4. query_charts upserted';

    -- ============================================================
    -- 5. 將兩個新組件加入 food_safety_tpe 儀表板
    --    同時補上 ntpc_food_factory（若尚未存在）
    -- ============================================================
    -- 6. 確保儀表板歸類正確 (分區隔離)
    -- food_safety_taipei (id=?) -> Group 2 (臺北市)
    SELECT id INTO v_food_dash_id FROM public.dashboards WHERE index = 'food_safety_taipei' LIMIT 1;
    IF v_food_dash_id IS NOT NULL THEN
        DELETE FROM public.dashboard_groups WHERE dashboard_id = v_food_dash_id AND group_id IN (2, 3);
        INSERT INTO public.dashboard_groups (dashboard_id, group_id) VALUES (v_food_dash_id, 2);
        
        -- 同步將新組件加入臺北儀表板
        UPDATE public.dashboards SET components = array_append(components, v_kitchen_cid::integer)
        WHERE id = v_food_dash_id AND NOT (components @> ARRAY[v_kitchen_cid::integer]);
        
        UPDATE public.dashboards SET components = array_append(components, v_pesticide_cid::integer)
        WHERE id = v_food_dash_id AND NOT (components @> ARRAY[v_pesticide_cid::integer]);
    END IF;

    -- food_safety_tpe (id=?) -> Group 3 (雙北)
    SELECT id INTO v_food_dash_id FROM public.dashboards WHERE index = 'food_safety_tpe' LIMIT 1;
    IF v_food_dash_id IS NOT NULL THEN
        DELETE FROM public.dashboard_groups WHERE dashboard_id = v_food_dash_id AND group_id IN (2, 3);
        INSERT INTO public.dashboard_groups (dashboard_id, group_id) VALUES (v_food_dash_id, 3);
        
        -- 確保雙北儀表板組件完整
        UPDATE public.dashboards SET components = array_append(components, v_kitchen_cid::integer)
        WHERE id = v_food_dash_id AND NOT (components @> ARRAY[v_kitchen_cid::integer]);
        
        UPDATE public.dashboards SET components = array_append(components, v_pesticide_cid::integer)
        WHERE id = v_food_dash_id AND NOT (components @> ARRAY[v_pesticide_cid::integer]);
    END IF;

    RAISE NOTICE '6. dashboard_groups isolation ensured';

    -- 最終狀態確認
    RAISE NOTICE '=== Migration add_school_kitchen_wholesale_components completed ===';
    RAISE NOTICE '    kitchen_map_id=%  pesticide_map_id=%', v_kitchen_map_id, v_pesticide_map_id;
    RAISE NOTICE '    kitchen_cid=%  pesticide_cid=%  ntpc_fac_cid=%',
        v_kitchen_cid, v_pesticide_cid, v_ntpc_fac_cid;

END $mig$;

COMMIT;
