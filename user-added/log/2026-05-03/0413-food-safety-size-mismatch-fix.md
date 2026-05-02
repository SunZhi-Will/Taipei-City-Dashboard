# 食安卡片尺寸誤判與動態長條圖高度修正 / Food Safety Tile Mis-sizing and Animated Bar Height Fix

## 2026-05-03 04:13

- objective:
  - 修正「臺北蔬果農藥檢驗」donut 卡片被誤判為 tall，導致尺寸不對。
  - 修正「食品中毒月度統計」動態長條圖顯示過扁（固定 210px）問題。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

- summary:
  - 移除 Dashboard 通用規則中的隨機放大條件（`(index + 1) % 6 === 0`），避免無語意卡片被放大。
  - 取消以 `chart_data` 長度泛化判定 tall 的策略，改為依 activeChart 類型驅動。
  - food_safety profile 的 `food_poisoning_trend` 改為動態規則：
    - `AnimatedColumnChart` -> `dashboard-tile--wide-tall`
    - 其他圖型 -> `dashboard-tile--wide`
  - `AnimatedColumnChart` 由固定高度 `210px` 改為容器自適應（`height: 100%` + `flex` 容器），並設定最小可視高度。

- change-type:
  - Fixed

- technical-details:
  - `DashboardView.vue`
    - `getTileClass(item)`：移除 `index` 參數依賴，避免位置導向的 random tall。
    - 移除 `hasDenseSeries` tall 判斷。
    - tall 判斷改為僅由 `hasTallActiveChart` 觸發。
    - food safety 專屬 profile：`food_poisoning_trend` 改為 function rule。
  - `AnimatedColumnChart.vue`
    - 外層新增 `.animcol-wrapper`（column flex，滿高）。
    - 圖表容器新增 `.animcol-chart`（`flex: 1`，`min-height: 260px`）。
    - `<VueApexCharts>` 高度由 `210px` 改為 `100%`。

- verification:
  - VS Code 診斷：
    - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` -> `No errors found`
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue` -> `No errors found`
  - 靜態檢查：`food_poisoning_trend` 在 animated bar 狀態會切到 `wide-tall`。

- performance-impact:
  - 減少不必要的 layout 變化（移除 random tall），整體視覺節奏更穩定。
  - animated bar 改為吃滿容器後，圖表可讀性提升，渲染成本變化可忽略。

- impact-risk:
  - 其他倚賴舊 `hasDenseSeries` 放大策略的卡片可能變回正常尺寸；若需要可再做 dashboard-specific 規則補強。
  - 若極窄視窗下 `min-height: 260px` 顯得擁擠，可再做 breakpoint 微調。

- regression-test:
  - 驗證「臺北蔬果農藥檢驗」donut 不再被套用 `dashboard-tile--tall`。
  - 驗證「食品中毒月度統計」切到動態長條圖時，高度明顯提升且內容不扁平。
  - 驗證其他多圖型切換仍可觸發動態尺寸更新。

- traceability:
  - Related request: 使用者回報「臺北蔬果農藥檢驗大小不對、動態條大小也不對」。

- next-actions:
  - 可進一步針對 `ColumnLineChart` 做專屬高度曲線，讓 trend 類切換更一致。
