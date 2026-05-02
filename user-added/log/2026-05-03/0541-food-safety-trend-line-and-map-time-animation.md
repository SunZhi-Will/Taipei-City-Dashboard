# 食安趨勢折線圖與地圖時間動畫 / Food Safety Trend Line And Map Time Animation

## 2026-05-03 05:41

- objective:
  - 讓「食品中毒月度統計」可切換折線圖
  - 讓「食品業者衛生稽查地圖」具備時間動畫圖

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - migrations/add_food_safety_components.sql
  - migrations/food_safety_components.sql

- summary:
  - `food_poisoning_trend` 的可用圖型補回 `TimelineSeparateChart`，使月度統計可在 AnimatedColumnChart 與折線圖間切換
  - `taipei_imap_food` 的可用圖型擴充為 `DonutChart, AnimatedColumnChart`
  - 為 `taipei_imap_food` 新增 `history_config` 與 `query_history`，提供按月份聚合的三條時序資料（合格 / 正在複查 / 不合格）
  - 前端 `DashboardComponent` 新增時間型圖表的資料來源切換邏輯：當 activeChart 為時間型圖表且存在 `history_data[0]` 時，改餵歷史時序資料，而不是原本的 `chart_data`

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `food_poisoning_trend`
    - `component_charts.types` 從僅有 `AnimatedColumnChart` 改為 `AnimatedColumnChart,TimelineSeparateChart`
    - 既有 `query_type=time` 與 `query_chart` 本來就符合折線圖資料格式，因此只需補 metadata
  - `taipei_imap_food`
    - `component_charts.types` 改為 `DonutChart,AnimatedColumnChart`
    - 新增 `history_config = {"range":["fiveyear_ago"],"color":["#4CAF50","#FF9800","#F44336"],"unit":"件"}`
    - 新增 `query_history`：依 `month` 與結果分類聚合成 time series，輸出 `x_axis(月份) / y_axis(分類) / data(件數)`
    - `taipei` 與 `metrotaipei` 兩個 city row 都同步補齊，避免 food_safety_taipei 與 food_safety_tpe 表現不一致
  - `DashboardComponent.vue`
    - 新增 `HISTORY_DRIVEN_CHARTS`
    - 新增 `activeSeries` computed：`AnimatedColumnChart`、`TimelineSeparateChart`、`TimelineStackedChart`、`ColumnLineChart` 優先吃 `history_data[0]`，否則回退到 `chart_data`

- verification:
  - metadata API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=metrotaipei' | jq '.data[] | select(.index=="food_poisoning_trend" or .index=="taipei_imap_food") | {index: .index, city: .city, chart_types: .chart_config.types, history_config: .history_config}'`
    - 結果：
      - `food_poisoning_trend.chart_types = ["AnimatedColumnChart","TimelineSeparateChart"]`
      - `taipei_imap_food.chart_types = ["DonutChart","AnimatedColumnChart"]`
      - `taipei_imap_food.history_config.range = ["fiveyear_ago"]`
  - history API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/component/45/history?city=taipei&timefrom=2021-01-01T00:00:00%2B08:00&timeto=2026-12-31T00:00:00%2B08:00' | jq '.'`
    - 結果回傳 3 條 series：`合格`、`正在複查`、`不合格`，每條皆有 `YYYY-MM-01T00:00:00+08:00` 月份點位
  - trend chart API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/component/47/chart?city=taipei' | jq '.data | length as $n | {series_count: $n, first_series_name: .[0].name, first_point: .[0].data[0]}'`
    - 結果顯示 time-series 正常，供 AnimatedColumnChart/TimelineSeparateChart 共用
  - VS Code diagnostics：
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` → No errors found
    - 兩個 migration 檔案 → No errors found

- performance-impact:
  - `taipei_imap_food` 新增一筆 history API 請求，僅在 dashboard 載入該 component 且有 `history_config.range` 時發生
  - 前端新增一個 computed 做資料來源切換，成本可忽略

- impact-risk:
  - `DashboardComponent` 現在會讓所有時間型圖表優先吃 `history_data[0]`；若未來某些時間型組件同時帶有不同語意的 `chart_data` 與 `history_data`，需再細化條件
  - `taipei_imap_food` 的時間動畫圖目前依賴 `month` 欄位格式固定為 `YYYY-MM`；若未來來源格式變動，`query_history` 需同步調整

- regression-test:
  - 重新整理 food_safety_tpe / food_safety_taipei
  - `food_poisoning_trend` 應可切到折線圖
  - `taipei_imap_food` 應可切到時間動畫圖，並顯示合格 / 正在複查 / 不合格三條月份序列
  - 驗證 `school_kitchen_imap` 與 `wholesale_pesticide_inspection` 仍保留在 dashboard 中

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0524-food-safety-donut-default-and-tile-sizing.md
    - user-added/log/2026-05-03/0521-food-safety-chart-toggle-and-dashboard-trim.md

- next-actions:
  - 若要讓 `taipei_imap_food` 的時間動畫圖與地圖月份切換雙向完全同步，可再補一版專用 layout/profile，讓 AnimatedColumnChart 狀態下 tile 更寬
