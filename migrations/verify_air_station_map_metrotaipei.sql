-- Verify: 確認 air_station_map_metrotaipei 4 筆 row 是否正確
-- ⚠️ 此 script 連 dashboardmanager DB（postgres-manager 容器）
-- 執行方式：
--   本機 psql：  psql -h localhost -p 5432 -d dashboardmanager -U <user> -f verify_air_station_map_metrotaipei.sql
--   Docker：     docker exec -i postgres-manager psql -U <user> -d dashboardmanager < verify_air_station_map_metrotaipei.sql

\echo === 1) 4 張表各應該有 1 筆 row（index = air_station_map_metrotaipei）===
SELECT 'components'      AS tbl, COUNT(*) AS n FROM public.components       WHERE index = 'air_station_map_metrotaipei'
UNION ALL
SELECT 'component_charts',       COUNT(*)    FROM public.component_charts WHERE index = 'air_station_map_metrotaipei'
UNION ALL
SELECT 'component_maps',         COUNT(*)    FROM public.component_maps   WHERE index = 'air_station_map_metrotaipei'
UNION ALL
SELECT 'query_charts',           COUNT(*)    FROM public.query_charts     WHERE index = 'air_station_map_metrotaipei';

\echo
\echo === 2) 組件 id 與 map id（接 dashboard 時會用到）===
SELECT
  c.id   AS component_id,
  cm.id  AS map_id,
  c.name
FROM public.components c
LEFT JOIN public.component_maps cm ON cm.index = c.index
WHERE c.index = 'air_station_map_metrotaipei';

\echo
\echo === 3) 確認 paint 與 property 是 JSONB（非字串）===
SELECT
  pg_typeof(paint)    AS paint_type,
  pg_typeof(property) AS property_type
FROM public.component_maps
WHERE index = 'air_station_map_metrotaipei';

\echo
\echo === 4) 確認 query_chart SQL 綁到正確的 map 與 city ===
SELECT
  index,
  city,
  query_type,
  map_config_ids,
  LEFT(query_chart, 80) AS query_chart_preview,
  contributors,
  links
FROM public.query_charts
WHERE index = 'air_station_map_metrotaipei';

\echo
\echo ⚠️ 注意：此 script 不會檢查 moenv_air_quality 資料新鮮度 — 那張表在另一個 DB（dashboard / postgres-data 容器）
\echo        想確認資料源，另跑 verify_data_moenv_air_quality.sql
