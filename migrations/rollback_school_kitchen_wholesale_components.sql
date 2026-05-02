-- =============================================================
-- Rollback: 食安地圖補完 / Rollback Food Safety Map Completion
-- =============================================================
-- 回滾 add_school_kitchen_wholesale_components.sql
-- 不回滾 ntpc_food_factory 的 dashboard 修正（保留）
-- =============================================================

BEGIN;

DO $rb$
DECLARE
    v_kitchen_cid     BIGINT;
    v_pesticide_cid   BIGINT;
    v_food_dash_id    BIGINT;
BEGIN
    SELECT id INTO v_kitchen_cid
    FROM public.components WHERE index = 'school_kitchen_imap' LIMIT 1;

    SELECT id INTO v_pesticide_cid
    FROM public.components WHERE index = 'wholesale_pesticide_inspection' LIMIT 1;

    SELECT id INTO v_food_dash_id
    FROM public.dashboards WHERE index = 'food_safety_tpe' LIMIT 1;

    -- 1. 從 food_safety_tpe 移除兩個新組件
    IF v_food_dash_id IS NOT NULL THEN
        IF v_kitchen_cid IS NOT NULL THEN
            UPDATE public.dashboards
            SET components = array_remove(components, v_kitchen_cid::integer),
                updated_at = NOW()
            WHERE id = v_food_dash_id;
        END IF;
        IF v_pesticide_cid IS NOT NULL THEN
            UPDATE public.dashboards
            SET components = array_remove(components, v_pesticide_cid::integer),
                updated_at = NOW()
            WHERE id = v_food_dash_id;
        END IF;
        RAISE NOTICE '1. Removed from food_safety_tpe dashboard';
    END IF;

    -- 2. 刪除 query_charts
    DELETE FROM public.query_charts
    WHERE index IN ('school_kitchen_imap', 'wholesale_pesticide_inspection');
    RAISE NOTICE '2. query_charts deleted';

    -- 3. 刪除 component_charts
    DELETE FROM public.component_charts
    WHERE index IN ('school_kitchen_imap', 'wholesale_pesticide_inspection');
    RAISE NOTICE '3. component_charts deleted';

    -- 4. 刪除 component_maps
    DELETE FROM public.component_maps
    WHERE index IN ('school_kitchen_imap', 'wholesale_pesticide_inspection');
    RAISE NOTICE '4. component_maps deleted';

    -- 5. 刪除 components
    DELETE FROM public.components
    WHERE index IN ('school_kitchen_imap', 'wholesale_pesticide_inspection');
    RAISE NOTICE '5. components deleted';

    RAISE NOTICE '=== Rollback add_school_kitchen_wholesale_components completed ===';
END $rb$;

COMMIT;
