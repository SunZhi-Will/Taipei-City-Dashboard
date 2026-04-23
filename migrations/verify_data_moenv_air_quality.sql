-- Verify: 確認資料源 moenv_air_quality 是最新狀態（DAG D050502 有跑）
-- ⚠️ 此 script 連 dashboard DB（postgres-data 容器），不是 dashboardmanager！
-- 執行方式：
--   Docker：  docker exec -i postgres-data psql -U <user> -d dashboard < verify_data_moenv_air_quality.sql
--
-- 備註：postgres-data 預設沒有對外曝 port，必須走 docker exec

\echo === 1) 表的存在性與資料筆數 ===
SELECT
  COUNT(*)                                                       AS total_rows,
  COUNT(*) FILTER (WHERE data_time > NOW() - INTERVAL '2 hour')  AS rows_in_last_2h,
  MAX(data_time)                                                 AS latest_data_time,
  MIN(data_time)                                                 AS earliest_data_time
FROM public.moenv_air_quality;

\echo
\echo === 2) 雙北測站清單（會在地圖顯示的點位） ===
SELECT site_name, county, aqi, status, pollutant, pm_2point5_ug_m3, data_time
FROM public.moenv_air_quality
ORDER BY county, site_name;

\echo
\echo === 3) 座標系驗證（應為 4326 WGS84） ===
SELECT DISTINCT ST_SRID(wkb_geometry) AS srid
FROM public.moenv_air_quality;

\echo
\echo ✅ 驗收標準：
\echo   - total_rows ≥ 10（雙北測站約 10-15 個）
\echo   - rows_in_last_2h ≥ 1（DAG 最近 2 小時有跑過）
\echo   - srid = 4326
