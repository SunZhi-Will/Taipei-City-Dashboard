-- Attach: 將 air_station_map_metrotaipei 組件掛到指定 dashboard
-- 預設目標：map-layers-metrotaipei

BEGIN;

-- 1) 先取得組件 ID 並嘗試更新 dashboard
UPDATE public.dashboards
SET 
  components = array_append(components, sub.comp_id),
  updated_at = NOW()
FROM (
  SELECT id AS comp_id 
  FROM public.components 
  WHERE index = 'air_station_map_metrotaipei'
) AS sub
WHERE 
  public.dashboards.index = 'map-layers-metrotaipei'
  AND NOT (sub.comp_id = ANY(public.dashboards.components));

COMMIT;

-- 驗證
SELECT index, components FROM public.dashboards WHERE index = 'map-layers-metrotaipei';
