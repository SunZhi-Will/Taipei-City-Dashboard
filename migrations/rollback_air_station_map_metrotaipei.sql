-- Rollback: 移除 air_station_map_metrotaipei 組件
-- 可重複執行（無資料時 DELETE 0 rows 不會 error）
-- 執行方式：psql -d dashboardmanager -f rollback_air_station_map_metrotaipei.sql

BEGIN;

-- 先從所有 dashboards.components 陣列移除此組件 id
DO $rb$
DECLARE
  v_component_id INTEGER;
BEGIN
  SELECT id INTO v_component_id
  FROM public.components
  WHERE index = 'air_station_map_metrotaipei';

  IF v_component_id IS NOT NULL THEN
    UPDATE public.dashboards
    SET components = array_remove(components, v_component_id)
    WHERE v_component_id = ANY(components);

    RAISE NOTICE '已從 dashboards 移除 component id=%', v_component_id;
  ELSE
    RAISE NOTICE '組件不存在，跳過 dashboard 清理';
  END IF;
END $rb$;

-- 照依賴順序 DELETE
DELETE FROM public.query_charts     WHERE index = 'air_station_map_metrotaipei';
DELETE FROM public.component_maps   WHERE index = 'air_station_map_metrotaipei';
DELETE FROM public.component_charts WHERE index = 'air_station_map_metrotaipei';
DELETE FROM public.components       WHERE index = 'air_station_map_metrotaipei';

COMMIT;
