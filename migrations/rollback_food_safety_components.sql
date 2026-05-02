-- =============================================================
-- Rollback: 食安月報儀表板 / Food Safety Dashboard
-- =============================================================
-- 對應 migration: add_food_safety_components.sql
-- 執行方式：
--   psql -d dashboardmanager -f migrations/rollback_food_safety_components.sql
-- =============================================================

BEGIN;

DO $rollback$
DECLARE
    v_taipei_food_cid   BIGINT;
    v_ntpc_factory_cid  BIGINT;
    v_fp_trend_cid      BIGINT;
    v_fp_cause_cid      BIGINT;
    v_fp_food_cid       BIGINT;
    v_fp_place_cid      BIGINT;
BEGIN
    -- 取得 component IDs（用於清理 dashboard components 陣列）
    SELECT id INTO v_taipei_food_cid  FROM public.components WHERE index = 'taipei_imap_food'     LIMIT 1;
    SELECT id INTO v_ntpc_factory_cid FROM public.components WHERE index = 'ntpc_food_factory'    LIMIT 1;
    SELECT id INTO v_fp_trend_cid     FROM public.components WHERE index = 'food_poisoning_trend' LIMIT 1;
    SELECT id INTO v_fp_cause_cid     FROM public.components WHERE index = 'food_poisoning_cause' LIMIT 1;
    SELECT id INTO v_fp_food_cid      FROM public.components WHERE index = 'food_poisoning_food'  LIMIT 1;
    SELECT id INTO v_fp_place_cid     FROM public.components WHERE index = 'food_poisoning_place' LIMIT 1;

    -- 1. 刪除 food_safety_tpe 儀表板
    DELETE FROM public.dashboards WHERE index = 'food_safety_tpe';

    -- 2. 從 map-layers-metrotaipei 移除 ntpc_food_factory
    IF v_ntpc_factory_cid IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_remove(components, v_ntpc_factory_cid),
            updated_at = NOW()
        WHERE index = 'map-layers-metrotaipei';
    END IF;

    -- 3. 刪除 query_charts
    DELETE FROM public.query_charts
    WHERE index IN (
        'taipei_imap_food', 'ntpc_food_factory',
        'food_poisoning_trend', 'food_poisoning_cause',
        'food_poisoning_food', 'food_poisoning_place'
    );

    -- 4. 刪除 component_charts
    DELETE FROM public.component_charts
    WHERE index IN (
        'taipei_imap_food', 'ntpc_food_factory',
        'food_poisoning_trend', 'food_poisoning_cause',
        'food_poisoning_food', 'food_poisoning_place'
    );

    -- 5. 刪除 component_maps
    DELETE FROM public.component_maps
    WHERE index IN ('taipei_imap_food', 'ntpc_food_factory');

    -- 6. 刪除 components
    DELETE FROM public.components
    WHERE index IN (
        'taipei_imap_food', 'ntpc_food_factory',
        'food_poisoning_trend', 'food_poisoning_cause',
        'food_poisoning_food', 'food_poisoning_place'
    );

    -- 7. 刪除 mock 資料表（謹慎：若 Airflow 已填入真實資料，請移除此段）
    DROP TABLE IF EXISTS public.food_poisoning_trend;
    DROP TABLE IF EXISTS public.food_poisoning_cause;
    DROP TABLE IF EXISTS public.food_poisoning_food;
    DROP TABLE IF EXISTS public.food_poisoning_place;

    RAISE NOTICE '=== Rollback add_food_safety_components completed ===';
END $rollback$;

COMMIT;
