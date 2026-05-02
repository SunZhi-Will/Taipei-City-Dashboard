# 台北批發農藥組件純化 / Taipei-Only Wholesale Pesticide Component

## 2026-05-03 02:58

- objective:
  - 將批發市場農藥檢驗組件做出台北專用版本，避免台北儀表板混入新北市場點位
  - 回應「可否做純台北版」需求並保持雙北儀表板既有內容不變

- files:
  - migrations/food_safety_components.sql
  - Taipei-City-Dashboard-FE/public/mapData/wholesale_pesticide_inspection_taipei.geojson

- summary:
  - 新增台北專用組件 `wholesale_pesticide_inspection_taipei`
  - 新增台北專用 map config（index 同名）並建立台北專用 query_charts（city=`taipei`）
  - 台北專用 query SQL 僅統計 `第一批發市場`、`第二批發市場`
  - 台北儀表板 `food_safety_taipei` 增加台北專用農藥組件
  - 雙北儀表板 `food_safety_tpe` 維持原 `wholesale_pesticide_inspection` + `ntpc_food_factory`

- change-type:
  - Added
  - Changed
  - Fixed

- technical-details:
  - `food_safety_components.sql`：
    - 新增變數：`v_taipei_wholesale_map_id`、`v_taipei_wholesale_cid`
    - 新增 component map：`wholesale_pesticide_inspection_taipei`
    - 新增 component / chart config：`wholesale_pesticide_inspection_taipei`
    - 新增 query_charts（city=taipei）並加上 `WHERE market IN ('第一批發市場', '第二批發市場')`
    - 原 `wholesale_pesticide_inspection` query_charts 改為只建立 `metrotaipei` 版本
    - `food_safety_taipei` components 陣列加入 `v_taipei_wholesale_cid`
    - 增加 `component_maps_id_seq` 自動校正，避免重跑時 PK 衝突
  - 新增 FE geojson：
    - `wholesale_pesticide_inspection_taipei.geojson`（由原檔篩出第一/第二批發市場）

- verification:
  - migration 套用：
    - `cat migrations/food_safety_components.sql | docker exec -i postgres-manager psql -v ON_ERROR_STOP=1 -U postgres -d dashboardmanager`
    - 結果 `BEGIN / DO / COMMIT`
  - 台北儀表板 API：
    - `GET /api/v1/dashboard/food_safety_taipei?city=taipei` 回傳 6 筆，含 `wholesale_pesticide_inspection_taipei`
  - 台北專用組件資料：
    - `GET /api/v1/component/<id>/chart?city=taipei` 成功回傳
  - 雙北儀表板 API：
    - `GET /api/v1/dashboard/food_safety_tpe?city=metrotaipei` 維持 7 筆
  - geojson 檢查：
    - `wholesale_pesticide_inspection_taipei.geojson` 僅含 `第一批發市場`、`第二批發市場`

- performance-impact:
  - 無顯著效能影響
  - 新增組件與 geojson 檔案，查詢與渲染成本在可控範圍

- impact-risk:
  - 台北儀表板組件數由 5 增為 6，UI 版面可能有輕微排序變化
  - 既有若硬編碼舊 index 名稱的腳本需留意新增 index

- regression-test:
  - 驗證台北食安頁：應顯示 `wholesale_pesticide_inspection_taipei`
  - 驗證台北地圖點位：不應出現「三重」「板橋」
  - 驗證雙北食安頁：仍顯示 `wholesale_pesticide_inspection` 與 `ntpc_food_factory`

- traceability:
  - related log: user-added/log/2026-05-03/0248-rename-and-split-food-safety-dashboards.md
  - related log: user-added/log/2026-05-03/0250-taipei-city-switch-rule-adjustment.md

- next-actions:
  - 建議同步更新 `migrations/add_food_safety_components.sql`，避免 legacy 初始化路徑與主 migration 行為不一致