# 修復地圖圖層儀表板 404 / Fix Map-Layers Dashboard 404

## 2026-05-03 02:35

- objective:
  - 修正地圖頁面載入時 `/api/v1/dashboard/map-layers-taipei` 與 `/api/v1/dashboard/map-layers-metrotaipei` 回傳 404 的問題
  - 將修復寫回 migration，避免下次重建 dashboardmanager metadata 時再次遺失

- files:
  - migrations/food_safety_components.sql
  - migrations/add_food_safety_components.sql

- summary:
  - 發現前端 `setMapLayers()` 會固定抓 `map-layers-{city}` dashboard
  - 目前 dashboardmanager 的 `dashboards` 表內已無 `map-layers-taipei` / `map-layers-metrotaipei`，導致 API 必然 404
  - 在兩份食安 migration 中補上「若缺少則建立 map-layers dashboards 與對應 dashboard_groups」的邏輯
  - 建立時只使用空 `components` 陣列，不覆蓋既有圖層內容，避免破壞已掛載的地圖組件

- change-type:
  - Fixed

- technical-details:
  - `food_safety_components.sql` 新增：
    - `map-layers-taipei` 缺少時自動建立，`group_id = 2`
    - `map-layers-metrotaipei` 缺少時自動建立，`group_id = 3`
  - `add_food_safety_components.sql` 同步加入相同保底邏輯，避免舊 migration 路徑重現問題
  - `dashboard_groups` schema 確認為 `(dashboard_id, group_id)`，非 city-based 欄位

- verification:
  - `cat migrations/food_safety_components.sql | docker exec -i postgres-manager psql -U postgres -d dashboardmanager` → `BEGIN / DO / COMMIT`
  - `SELECT d.id, d.index, d.name, d.components, dg.group_id ... WHERE d.index IN ('map-layers-taipei','map-layers-metrotaipei')` → 查得兩筆 dashboard 與 group 2/3
  - `curl http://localhost:8088/api/v1/dashboard/map-layers-taipei?city=taipei` → HTTP 200
  - `curl http://localhost:8088/api/v1/dashboard/map-layers-metrotaipei?city=metrotaipei` → HTTP 200

- performance-impact:
  - 無直接效能影響
  - 僅補 metadata 保底邏輯

- impact-risk:
  - 目前 `map-layers-*` dashboards 可正常回傳，但 `data` 為 `null`，代表 dashboard 已存在但暫無掛載圖層組件
  - 若要恢復地圖圖層內容，仍需再套用相關 map layer migration（如 `add_7_static_map_layers.sql`）

- regression-test:
  - 開啟地圖頁面，確認 console 不再出現 `GET /api/dev/dashboard/map-layers-taipei 404`
  - 驗證 `setMapLayers()` 在 `response.data.data || []` 路徑下可正常降級為空陣列
  - 若需圖層內容，重跑 map layer migration 後再驗證地圖側欄清單

- traceability:
  - 相關前端呼叫點：Taipei-City-Dashboard-FE/src/store/contentStore.js
  - 相關 schema 參考：db-sample-data/dashboardmanager-demo.sql

- next-actions:
  - 可再補回 `add_7_static_map_layers.sql` 或其他 map layer migration，讓 `map-layers-*` dashboard 有實際圖層內容
  - 可另外處理 `taipei_building_3d` source layer not found 警告