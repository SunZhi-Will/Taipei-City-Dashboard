# 食安圖表 500 與地圖降噪修正 / Food Safety Chart 500 and Map Noise Reduction Fix

## 2026-05-03 05:05

- objective:
  - 修正 component 52 圖表 API 回傳 500 的根本 SQL 錯誤
  - 讓 geolocation 被瀏覽器封鎖與 3D 建物 tileset 不相容時，前端以降級方式處理而非持續輸出高噪音錯誤

- files:
  - migrations/food_safety_components.sql
  - migrations/add_school_kitchen_wholesale_components.sql
  - Taipei-City-Dashboard-FE/src/store/mapStore.js

- summary:
  - 修正 `wholesale_pesticide_inspection` 的 query_chart SQL，避免 grouped query 在 `ORDER BY` 使用未聚合欄位 `result` 導致 PostgreSQL 42803
  - 將排序邏輯改為 `ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)`，同時保留「合格在前、不合格在後」的視覺順序
  - 地圖初始化改為先檢查 geolocation permission；若權限已被瀏覽器封鎖，直接不加入 `GeolocateControl`
  - 3D buildings 改為在 source-layer 不存在時移除 layer/source 並只警告一次，避免同類 console 訊息反覆出現

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `migrations/food_safety_components.sql` 與 `migrations/add_school_kitchen_wholesale_components.sql`
    - 原查詢：`GROUP BY 1 ORDER BY CASE WHEN result = '合格' THEN 1 ELSE 2 END`
    - 修正後：`GROUP BY 1 ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)`
    - 這避免 PostgreSQL 對 grouped query 的欄位聚合限制，並讓舊初始化路徑與新初始化路徑保持一致
  - `Taipei-City-Dashboard-FE/src/store/mapStore.js`
    - 新增 geolocation denied 狀態追蹤，避免權限被永久封鎖時每次操作都輸出 `User denied Geolocation`
    - 新增 `addGeolocateControl()`，透過 `navigator.permissions.query({ name: 'geolocation' })` 在可用時才掛載控制元件
    - 對 Taipei 3D buildings 的 Mapbox error listener 改為一次性停用策略：偵測到 source/layer 不相容後即移除圖層與 source，避免事件持續觸發
  - 現場資料同步：已直接更新 `dashboardmanager.query_charts` 內 `index='wholesale_pesticide_inspection'` 的 `taipei` / `metrotaipei` 兩筆 SQL，讓目前執行中的環境立即生效

- verification:
  - 前端語法檢查：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/store/mapStore.js`，結果 `No errors found`
  - API 驗證：
    - `curl http://localhost:8080/api/dev/component/52/chart?city=taipei`
      - 回傳：`{"data":[{"data":[{"x":"不合格","y":45}]}],"status":"success"}`
    - `curl http://localhost:8080/api/dev/component/52/chart?city=metrotaipei`
      - 回傳：`{"data":[{"data":[{"x":"合格","y":37697},{"x":"不合格","y":1557}]}],"status":"success"}`
  - 資料庫同步：
    - 以 `docker exec -i postgres-manager psql -U postgres -d dashboardmanager` 直接更新 `query_charts` 中兩筆 `wholesale_pesticide_inspection` 的 `query_chart`
    - 執行結果：`UPDATE 1`、`UPDATE 1`

- performance-impact:
  - chart query 本身仍為小型聚合查詢，改用 `MIN(CASE ...)` 不會造成可感知效能退化
  - 3D building source layer 不相容時會更早停用，能減少重複 error event 與 console 輸出

- impact-risk:
  - geolocation browser permission 若已被使用者封鎖，仍需使用者於瀏覽器 Page Info 手動重設；本次修正僅改為前端安靜降級，不會代替瀏覽器重設權限
  - 3D buildings tileset 若之後更新為正確 source layer，需重新整理頁面才能重新掛載圖層
  - 本次直接同步現場 DB，其他尚未套用 migration 的環境仍需透過 migration 或 SQL 更新帶入修正

- regression-test:
  - 開啟食安頁面，確認 component 52 不再出現 500，且 donut/bar 能正常渲染
  - 在 geolocation 權限為 denied 的瀏覽器中重新整理地圖頁，確認不再連續輸出 `User denied Geolocation`
  - 在沒有對應 `tp_building_height84-18p8j0` source layer 的 tileset 環境中刷新地圖，確認 3D building 僅警告一次且不持續報錯

- traceability:
  - related runtime symptom: `GET /api/dev/component/52/chart?city=taipei|metrotaipei -> 500`
  - related memory: `/memories/repo/food-safety-chart-sql.md`
  - related prior work: `user-added/log/2026-05-03/0258-taipei-only-wholesale-component.md`

- next-actions:
  - 建議在其他共享環境同步執行相同 `query_charts` 更新，或重新套用相關 migration，避免僅本機修復