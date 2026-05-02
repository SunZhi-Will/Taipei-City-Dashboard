# 食安圖表全 0 查詢修復 / Fix Zeroed Food Safety Chart Queries

## 2026-05-03 05:12

- objective:
  - 修正食品業者衛生稽查地圖與臺北市學校廚房稽查 DonutChart 顯示全 0 的問題
  - 釐清 food_safety_tpe 中 map 型組件的 chart query 實際資料來源

- files:
  - migrations/add_food_safety_components.sql
  - migrations/add_school_kitchen_wholesale_components.sql
  - migrations/fix_food_safety_zero_chart_queries.sql

- summary:
  - 找出根因為 dashboardmanager.query_charts 中 taipei city 的食安查詢被寫成 0 陣列 placeholder，而 component chart endpoint 直接執行該 SQL，因此前端甜甜圈圖顯示全 0
  - 將 taipei_imap_food 的 migration 與現場修復 SQL 改為直接統計 dashboard 資料表
  - 將 school_kitchen_imap 改為使用現有 GeoJSON 對應的靜態真實分佈值，避免查詢不存在的資料表

- change-type:
  - Fixed
  - Changed

- technical-details:
  - taipei_imap_food:
    - 原本 `query_chart` 為 `unnest(ARRAY[0,0,0])`
    - 改為 `public.taipei_imap_food` 動態統計，分群規則為 A1/A2→合格、A3→正在複查、其他→不合格
    - 排序由 `CASE x_axis` 改為 `ORDER BY MIN(CASE ...)`，避免 PostgreSQL 在執行 component chart SQL 時出現 `column "x_axis" does not exist`
  - school_kitchen_imap:
    - 驗證 dashboard DB 無 `public.school_kitchen_imap` 表，無法用動態 SQL 統計
    - 以 `Taipei-City-Dashboard-FE/public/mapData/school_kitchen_imap.geojson` 現況統計值回填為靜態 query：A1優良=40、A2合格=12、B1限改=1、不符規定=1
  - 新增 `migrations/fix_food_safety_zero_chart_queries.sql`，用於修正既有環境的 `dashboardmanager.query_charts`

- verification:
  - 套用現場修復：`docker exec -i postgres-manager psql -U postgres -d dashboardmanager < migrations/fix_food_safety_zero_chart_queries.sql` → `BEGIN / UPDATE 1 / UPDATE 1 / COMMIT`
  - API 驗證：`curl -s "http://localhost:8088/api/v1/component/45/chart?city=taipei" | jq '.'`
    - 回傳 `合格=12774 / 正在複查=689 / 不合格=232`
  - API 驗證：`curl -s "http://localhost:8088/api/v1/component/37/chart?city=taipei" | jq '.'`
    - 回傳 `A1優良=40 / A2合格=12 / B1限改=1 / 不符規定=1`
  - 診斷檢查：VS Code diagnostics 對三個 migration 檔案皆為 `No errors found`

- performance-impact:
  - taipei_imap_food chart 由靜態常數改為即時計數，查詢成本略增但資料量仍屬小型單表聚合
  - school_kitchen_imap 仍為靜態查詢，無額外執行成本

- impact-risk:
  - school_kitchen_imap 目前仍依賴靜態 GeoJSON 統計，若 FE GeoJSON 更新而未同步更新 query_charts，數值可能再次偏移
  - taipei_imap_food 僅影響 taipei city 的 chart query，不影響其他 city row 與地圖圖層資料

- regression-test:
  - 重新開啟 food_safety_tpe 或 map 分析面板，確認兩個 DonutChart 不再顯示 0
  - 驗證 `http://localhost:8088/api/v1/component/45/chart?city=taipei` 與 `http://localhost:8088/api/v1/component/37/chart?city=taipei` 皆為 200 success
  - 後續若更新 school_kitchen GeoJSON，需同步更新 `fix_food_safety_zero_chart_queries.sql` 或補建正式資料表/ETL

- traceability:
  - related logs:
    - user-added/log/2026-05-02/2329-food-safety-map-completion.md
    - user-added/log/2026-05-02/2345-food-safety-chart-zeros-fix.md

- next-actions:
  - 補建 school_kitchen_imap 的正式資料表或 ETL，避免長期依賴靜態統計值
  - 若前端需要月別動態甜甜圈，需讓 school_kitchen 的 chart endpoint 能讀取月份分佈而非總量統計
