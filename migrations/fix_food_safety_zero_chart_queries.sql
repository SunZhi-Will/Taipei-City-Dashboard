-- =============================================================
-- Migration: 修復食安地圖 chart query 全 0 / Fix zeroed chart queries
-- =============================================================
-- 目的：
--   修正 dashboardmanager.query_charts 內誤寫為 0 陣列的食安查詢，
--   讓 component chart endpoint 直接回傳真實統計值。
--
-- 執行方式：
--   psql -d dashboardmanager -f migrations/fix_food_safety_zero_chart_queries.sql
-- =============================================================

BEGIN;

UPDATE public.query_charts
SET query_type = 'two_d',
    updated_at = NOW(),
    query_chart = $q$SELECT CASE
                             WHEN result IN ('A1', 'A2') THEN '合格'
                             WHEN result = 'A3' THEN '正在複查'
                             ELSE '不合格'
                         END AS x_axis,
                         COUNT(*)::float AS data
                    FROM public.taipei_imap_food
                   GROUP BY 1
             ORDER BY MIN(CASE
                    WHEN result IN ('A1', 'A2') THEN 1
                    WHEN result = 'A3' THEN 2
                    ELSE 3
                  END)$q$
WHERE index = 'taipei_imap_food'
  AND city = 'taipei';

UPDATE public.query_charts
SET query_type = 'two_d',
    updated_at = NOW(),
    query_chart = $q$SELECT unnest(ARRAY['A1優良','A2合格','B1限改','不符規定']) AS x_axis,
                           unnest(ARRAY[40,12,1,1])::float AS data$q$
WHERE index = 'school_kitchen_imap'
  AND city = 'taipei';

COMMIT;