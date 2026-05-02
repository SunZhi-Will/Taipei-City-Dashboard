# 圖型切換與版型同步修正 / Chart Switch and Layout Sync Fix

## 2026-05-03 03:24

- objective:
  - 修正元件在圖型切換後只重畫圖表、但外層卡片高度未同步更新，導致內容出現上下滑輪。
  - 讓 Dashboard tile 依目前 activeChart 即時調整跨度，特別是 DonutChart 切到 BarChart 的情境。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 新增 `componentActiveCharts` 狀態，於 DashboardView 記錄每張卡片當前 activeChart。
  - DashboardComponent 在初始載入與每次切換圖型時，透過 `chart-type-change` 事件回傳當前 chart type。
  - `getTileClass()` 改為依 `activeChart` 而非僅依 component 可用圖型列表判斷版型，讓卡片高度與目前圖型同步。
  - 對 food_safety_tpe / food_safety_taipei 的 `food_poisoning_food`、`food_poisoning_cause` 加入動態規則：切到 `BarChart` 時自動升級為 `dashboard-tile--x-tall`。

- change-type:
  - Fixed

- technical-details:
  - `DashboardView.vue`
    - 新增 `componentActiveCharts = ref({})`
    - dashboard 切換時同步清空 activeChart cache
    - `TALL_CHART_TYPES` 納入 `BarPercentChart`
    - `getTileClass()` 新增：
      - `activeChart = componentActiveCharts[item.id] || item.chart_config.types[0]`
      - profile class 若為 function，則以 `activeChart` 計算
      - 多圖型卡切到 tall activeChart 時套用 `dashboard-tile--x-tall`
    - 新增 `handleChartTypeChange(componentId, chartType)`
    - 各 DashboardComponent 實例皆接上 `@chart-type-change`
  - `DashboardComponent.vue`
    - `defineEmits` 新增 `chartTypeChange`
    - `watch(activeChart, ..., { immediate: true })`
    - 在 watch 中先 emit `chartTypeChange(config.id, activeChart)`，再觸發 resize

- verification:
  - VS Code 診斷：
    - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` -> `No errors found`
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` -> `No errors found`
  - 靜態檢查：確認 food safety profile 會在 activeChart=`BarChart` 時回傳 `dashboard-tile--x-tall`。

- performance-impact:
  - 新增一層 activeChart 狀態同步，成本很低，僅在圖型切換時更新。
  - 以版型同步取代卡內捲動，可降低使用者反覆在元件內滾動的操作成本。

- impact-risk:
  - 若未來有更多 dashboard 需要圖型切換驅動版型，可能需把目前 pattern 抽象成共用 schema。
  - 若 component `id` 在極少數場景非穩定值，activeChart cache 需再加防呆處理。

- regression-test:
  - 在 `致病原因分布` / `可能中毒食品分布` 由 `DonutChart` 切換到 `BarChart`，確認 tile 高度同步增加且不再出現上下滑輪。
  - 切回 donut 後確認 tile 可恢復原節奏。
  - 驗證其他非多圖型 dashboard 不受影響。

- traceability:
  - Related request: 使用者回報「切換後大小要更新，不然又變成內容要滑輪上下動」。

- next-actions:
  - 若要更平滑的 UIUX，可再加入 tile 高度切換動畫，讓 donut/bar 切換時版面重排更自然。
