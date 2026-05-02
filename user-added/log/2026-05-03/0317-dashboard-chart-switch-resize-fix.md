# 多圖型切換尺寸重算與裁切修正 / Multi-Chart Switch Resize and Clipping Fix

## 2026-05-03 03:17

- objective:
  - 修正同一元件切換圖表型態後，容器高度未重算導致文字/標籤被裁切。
  - 讓多圖型元件在網格中獲得更充足空間，降低切換後內容溢出風險。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 在 dashboard tile 分級規則加入「多圖型」判定，新增更高跨度類別：`dashboard-tile--x-tall`、`dashboard-tile--wide-tall`。
  - 將 `DashboardComponent` 主內容渲染改為「僅渲染 activeChart」，避免多圖同時掛載造成尺寸狀態殘留。
  - 於圖型切換（`activeChart`）後觸發 resize event，讓 ApexCharts 依當前容器重新計算尺寸。
  - 調整內容區 overflow 行為為 `overflow-y: auto`、`overflow-x: hidden`，避免裁切時完全不可讀。

- change-type:
  - Fixed

- technical-details:
  - `DashboardView.vue`
    - `getTileClass()` 新增：
      - `hasMultiChartTypes && hasWideChartType` -> `dashboard-tile--wide-tall`
      - `hasMultiChartTypes` -> `dashboard-tile--x-tall`
    - 新增 CSS:
      - `.dashboard-tile--x-tall { grid-row: span 4; }`
      - `.dashboard-tile--wide-tall { grid-column: span 2; grid-row: span 3; }`
    - 手機斷點維持全部 tile 回退單欄單列跨度。
  - `DashboardComponent.vue`
    - `import` 增加 `watch`、`nextTick`。
    - 新增 `watch(activeChart)` 在切換後 `requestAnimationFrame` 觸發 `window.resize`。
    - 將主內容 `<component>` 從 `v-for` 多實例改為單一 active 實例（`returnChartComponent(activeChart)`）。

- verification:
  - VS Code 診斷檢查：
    - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` -> `No errors found`
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` -> `No errors found`
  - 靜態檢查模板：主內容區僅保留單一 active 圖型渲染，避免舊圖型尺寸快取干擾。

- performance-impact:
  - 減少非 active 圖型同時渲染的開銷，理論上可略降記憶體與重繪負擔。
  - 增加切換後一次 resize 事件，成本可接受且僅在切換發生。

- impact-risk:
  - 多圖型卡片高度增加後，單頁可視卡片數量可能降低。
  - 若個別圖表元件未正確響應 resize 事件，仍可能需要該元件內部微調。

- regression-test:
  - 在「致病原因分布」中切換「圓餅圖/橫向長條圖」，確認文字與標籤不再被切割。
  - 驗證含多圖型元件在桌機寬度下是否套用更高 tile。
  - 驗證手機版仍為單欄且無版面破壞。

- traceability:
  - Related request: 使用者回報「元件內多圖表切換後大小沒變，導致文字被切割」。

- next-actions:
  - 若仍有個別圖型被截斷，可針對該圖型（如 Donut/Timeline）加入最小可視高度或動態字級策略。
