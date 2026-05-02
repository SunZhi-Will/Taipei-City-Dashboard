# 圖表單位 null 顯示修正 / Fix null unit display in all chart components

## 2026-05-02 00:04

- objective:
  - 臺北市食品抽驗月報等組件的 tooltip / 標題出現「數字 null」文字
  - 根本原因：`component_charts.unit = NULL` 時，JavaScript `` ` ${props.chart_config.unit}` `` 會把 `null` 強轉成字串 `"null"` 拼入 HTML；Vue 模板 `{{ chart_config.unit }}` 同理
  - 確認所有含 play/pause 的組件均已使用 Material Icons

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarPercentChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarChartWithGoal.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/ColumnChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/ColumnLineChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/HeatmapChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TimelineSeparateChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TimelineStackedChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/IndicatorChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TreemapChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/MapLegend.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DistrictChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/PolarAreaChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/SpeedometerChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/RadarChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/IconPercentChart.vue

- summary:
  - 所有圖表組件中凡使用 `props.chart_config.unit` 的地方，一律加上 `?? ''` null coalescing 防護
  - JS 樣板字串：`` ` ${props.chart_config.unit}` `` → `` ` ${props.chart_config.unit ?? ''}` ``
  - Vue 模板插值：`{{ chart_config.unit }}` → `{{ chart_config.unit ?? '' }}`
  - BarChartWithGoal 同時修正 value 與 goalValue 兩個 tooltip span
  - 確認 play/pause 狀態：DonutChart、AnimatedColumnChart、MapLegend、TimelineSeparateChart、AIStudioPresentationCanvas 均已使用 `<span class="material-icons">play_arrow / pause</span>`，無需修改

- change-type:
  - Fixed

- technical-details:
  - JavaScript 的型別強制轉換：`null + ''` = `"null"` / `` `${null}` `` = `"null"`
  - Null coalescing (`??`) 選擇空字串而非 `||`，以避免數字 0 被誤判為 falsy 的邊界問題
  - 影響組件：17 個圖表組件，涵蓋 tooltip custom function（JS 字串拼接）與 Vue 模板插值兩種模式

- verification:
  - `grep -r "chart_config\.unit" src/dashboardComponent/components/ | grep -v '?? '`
  - 確認結果：0 matches（全部已修正）
  - 食安儀表板直接受影響組件：taipei_imap_food (DonutChart, unit=NULL)、ntpc_food_factory (MapLegend, unit=NULL)

- impact-risk:
  - 影響全部使用 unit 欄位的圖表組件（17 個）
  - 低風險：僅改 null → 空字串，不影響已有 unit 值的組件顯示
  - 原本就有 unit 的組件（如 '件'）行為完全不變

- regression-test:
  - 驗證有 unit（如 '件'）的組件：tooltip 仍顯示 "8 件"
  - 驗證無 unit（NULL）的組件：tooltip 顯示 "8 "（尾隨空格可接受）或 "8"
  - 食安儀表板各組件 tooltip hover 確認無 "null" 文字
  - 播放/暫停按鈕確認顯示 Material Icon（play_arrow / pause）

- traceability:
  - 相關 log: user-added/log/2026-05-02/2345-food-safety-chart-zeros-fix.md
  - 相關 log: user-added/log/2026-05-02/2329-food-safety-map-completion.md

- next-actions:
  - 若後續新增圖表組件，需同樣在 unit 使用處加 `?? ''`
  - 可考慮在 DashboardComponent 的 props 傳入層加 computed 做一次性 null guard
