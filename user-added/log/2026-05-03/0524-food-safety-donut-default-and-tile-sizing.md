# 食安圓餅圖預設與尺寸修正 / Food Safety Donut Default And Tile Sizing

## 2026-05-03 05:24

- objective:
  - 讓食安分類組件預設優先顯示圓餅圖
  - 修正 food safety dashboard 切換 Bar/Donut 時尺寸幾乎不變的體感問題

- files:
  - migrations/add_food_safety_components.sql
  - migrations/food_safety_components.sql
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 將 `food_poisoning_cause`、`food_poisoning_food`、`food_poisoning_place` 的 chart type 順序改為 `DonutChart,BarChart`，使所有預設邏輯優先落在圓餅圖
  - 將 food safety dashboard 中 `food_poisoning_place` 的 tile class 從固定 tall 改為僅在 `BarChart` 時才套用，讓切到 Donut 時版面會縮回標準尺寸
  - 重新套用 metadata migration，並補跑 school/wholesale migration，確保 dashboard 組件清單不被覆寫

- change-type:
  - Changed
  - Fixed

- technical-details:
  - 前端預設 chart 邏輯來自 `DashboardComponent.vue`：若未指定 `initialChartType`，直接使用 `config.chart_config.types[0]`
  - 因此只要 metadata 順序仍是 `BarChart,DonutChart`，畫面預設就一定會先顯示橫條圖
  - `DashboardView.vue` 的 `DASHBOARD_LAYOUT_PROFILES` 會覆寫 tile 尺寸；先前 `food_poisoning_place` 被固定為 `dashboard-tile--tall`，即使切到 Donut 也不會變小
  - 本次將 `food_poisoning_place` 改成依 `activeChart === 'BarChart'` 才套用 tall，Donut 時回到預設尺寸

- verification:
  - API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=metrotaipei' | jq '.data[] | select(.index=="food_poisoning_cause" or .index=="food_poisoning_food" or .index=="food_poisoning_place") | {index: .index, chart_types: .chart_config.types}'`
    - 三個組件皆回傳 `DonutChart, BarChart`
  - DB 驗證：
    - `SELECT index, types FROM component_charts WHERE index IN ('food_poisoning_cause','food_poisoning_food','food_poisoning_place') ORDER BY index;`
    - 三個組件皆為 `{DonutChart,BarChart}`
  - DB 驗證：
    - `SELECT index, components FROM dashboards WHERE index IN ('food_safety_tpe','food_safety_taipei') ORDER BY index;`
    - 兩個 dashboard 皆維持 `{45,47,48,49,50,37,52}`
  - VS Code diagnostics：
    - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` → No errors found
    - 兩個 migration 檔案 → No errors found

- performance-impact:
  - 僅 metadata 順序與 layout class 條件調整，無額外查詢或渲染成本

- impact-risk:
  - 若之後後端再次覆寫 `component_charts.types` 順序，預設圖表仍可能被改回 Bar 優先
  - 目前 `food_poisoning_cause`、`food_poisoning_food` 的 tile 本來就只有 Bar 時才會拉高；本次主要補齊 `food_poisoning_place` 的一致性

- regression-test:
  - 重新整理 food_safety_tpe / food_safety_taipei，三個分類組件應預設顯示 Donut
  - 切換三個分類組件至 BarChart 時，tile 高度應拉高
  - 再切回 Donut 時，tile 高度應恢復一般尺寸

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0521-food-safety-chart-toggle-and-dashboard-trim.md

- next-actions:
  - 若要讓切換後的圖表選擇跨重新整理持久化，可再加使用者偏好快取
