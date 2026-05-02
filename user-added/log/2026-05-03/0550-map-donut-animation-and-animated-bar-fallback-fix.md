# 圓餅圖動畫控制與動態長條圖備援修正 / Fix Donut Animation Controls and Animated Bar Fallback

## 2026-05-03 05:50

- objective:
  - 修正食品業者衛生稽查地圖在「圓餅圖」模式仍顯示月份動畫控制列的錯誤行為。
  - 修正「動態長條圖」在缺少 history series 時整塊空白，改為可回退使用地圖月份統計。
  - 將 `taipei_imap_food` 預設圖型改回圓餅圖，避免初始即落在可能無資料的動畫圖。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - `DonutChart` 的 `showAnimControls` 改為需符合 `activeChart === "AnimatedColumnChart"` 才顯示，圓餅圖模式不再出現播放按鈕與月份滑桿。
  - `AnimatedColumnChart` 新增 map 月份統計備援：當 `props.series` 沒有合法 `YYYY-MM` 時序點時，改讀 `timeStore.monthResultCounts[map_index]` 建立月份與分類資料。
  - `AnimatedColumnChart` 無資料時新增提示文字「暫無可播放的月份資料」，避免使用者看到空白區塊。
  - `DashboardView` 將 `food_safety_tpe` / `food_safety_taipei` 的 `taipei_imap_food` 預設型別改為 `DonutChart`。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `AnimatedColumnChart.vue`
    - 新增 `RESULT_ORDER = ["合格", "正在複查", "不合格"]`。
    - 新增 `mapMonthlyData`、`hasSeriesMonthData`、`effectiveMonthlyData` 三層 computed，建立「history 優先、map 備援」資料流。
    - `currentMonth`、`currentSeries`、slider 上限、`onMonthSelect`、播放循環長度皆改讀 `effectiveMonthlyData`。
    - `currentSeries.name` 改為「件數」，避免語意固定為「不合格」。
  - `DonutChart.vue`
    - 修正動畫列顯示條件，避免圓餅圖模式誤顯示動態控制器。
  - `DashboardView.vue`
    - `DASHBOARD_DEFAULT_CHART_TYPES` 中 `taipei_imap_food` 改回 `DonutChart`。

- verification:
  - VS Code diagnostics：
    - `get_errors` 檢查 `DonutChart.vue`、`AnimatedColumnChart.vue`、`DashboardView.vue` 皆為 `No errors found`。
  - 程式碼檢查：
    - 確認 `DonutChart` template 的 `donutchart-anim` 區塊仍受 `showAnimControls` 控制。
    - 確認 `AnimatedColumnChart` template 在 `activeChart === "AnimatedColumnChart"` 且無月份資料時會顯示文字提示，不再渲染空白。

- performance-impact:
  - 新增的 computed 只在切圖或月份資料變動時計算，屬低成本。
  - map 備援分支僅讀取已快取於 store 的 `monthResultCounts`，不增加額外 API 請求。

- impact-risk:
  - 若其他場景刻意希望在 `DonutChart` 模式顯示月份控制列，現在會被隱藏（目前需求判定屬正確修正）。
  - map 備援資料依賴 GeoJSON metadata 或 feature 掃描結果；若來源資料沒有 `month`，仍會顯示無資料提示。

- regression-test:
  - 在 food_safety_tpe / food_safety_taipei，切換 `taipei_imap_food`：
    - 圓餅圖模式不應出現播放鍵與時間滑桿。
    - 切到動態長條圖，若 history API 缺資料但 map 月份統計存在，仍應顯示柱狀圖。
    - 若兩者都無月份資料，應顯示「暫無可播放的月份資料」。

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0541-food-safety-trend-line-and-map-time-animation.md
    - user-added/log/2026-05-03/0535-dashboardcomponent-activechart-reset-fix.md

- next-actions:
  - N/A
