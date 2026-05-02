-- Rollback: 移除 add_7_static_map_layers.sql 所新增的 7 個地圖組件
-- 執行方式: psql -d dashboardmanager -f migrations/rollback_7_static_map_layers.sql

BEGIN;

DO $rb$
DECLARE
  v_ids BIGINT[];
  v_id  BIGINT;
BEGIN
  -- 取得所有要刪除的 component IDs
  SELECT array_agg(id) INTO v_ids
  FROM public.components
  WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- 從 dashboards 移除組件 ID
  IF v_ids IS NOT NULL THEN
    UPDATE public.dashboards
    SET components = array(
      SELECT unnest(components)
      EXCEPT
      SELECT unnest(v_ids)
    ),
    updated_at = NOW()
    WHERE index IN ('map-layers-taipei', 'map-layers-metrotaipei');
  END IF;

  -- 刪除 query_charts
  DELETE FROM public.query_charts WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- 刪除 component_maps
  DELETE FROM public.component_maps WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- 刪除 component_charts
  DELETE FROM public.component_charts WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- 刪除 components
  DELETE FROM public.components WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  RAISE NOTICE 'Rollback 完成：7 個地圖組件已移除。';
END $rb$;

COMMIT;

-- 驗證
SELECT index, array_length(components, 1) AS num_components
FROM public.dashboards
WHERE index IN ('map-layers-taipei', 'map-layers-metrotaipei');
