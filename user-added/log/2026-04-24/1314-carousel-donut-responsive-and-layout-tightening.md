# 輪播 Donut 自適應與版面緊縮修正 / Carousel Donut Responsive Sizing and Layout Tightening

## 2026-04-24 13:14

- objective:
  - 解決輪播中 Donut 圖表只顯示小尺寸（約 300px）與大面積留白問題。
  - 讓輪播展示以圖表內容為主，不被 Dashboard header/control/footer 擠壓。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - DonutChart 改為顯式跟隨父容器 100% 寬高，並啟用父容器 resize 重繪。
  - 輪播的 `slide-chart-container` 改為強制隱藏 `dashboardcomponent-header` 與 `dashboardcomponent-control`，並壓縮內距。
  - 強化 `dashboardcomponent-chart` 與 donutchart 高度規則，避免內容被固定尺寸或 padding 壓縮。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `DonutChart.vue`:
    - `chartOptions.chart` 新增：`width: "100%"`, `height: "100%"`, `redrawOnParentResize: true`, `redrawOnWindowResize: true`。
    - `<VueApexCharts>` 新增 `height="100%"`。
    - `donutchart` 新增對 `.vue-apexcharts/.apexcharts-canvas/.apexcharts-svg` 的 100% 強制尺寸。
  - `AIStudioPresentationCanvas.vue`:
    - `.slide-chart-container :deep(.dashboardcomponent)` 加入 `padding: 0`、`min-height: 0`。
    - `.dashboardcomponent-header`、`.dashboardcomponent-control` 改為 `display: none !important`。
    - `.dashboardcomponent-chart` 改為 `height: 100% !important` 並移除頂部 padding/scroll 影響。

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 版面重排更直接，減少不必要區塊渲染與空白佔用。
  - resize 重繪在容器/視窗變更時觸發，屬可接受成本，換取穩定視覺一致性。

- impact-risk:
  - 中低風險：DonutChart 為全域元件，若其他場景依賴舊尺寸行為，可能需微調局部樣式。
  - 輪播專屬樣式以 scoped + deep 作用於 `slide-chart-container`，對一般頁面影響低。

- regression-test:
  - 進入 AI Studio 輪播並切到 Donut 類型組件，確認圖表可貼合容器，不再固定小尺寸。
  - 驗證輪播中不再顯示 Dashboard header/control/footer，圖表可視區明顯增大。
  - 驗證一般 Dashboard 頁面 Donut 顯示未異常。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍有特定圖型（非 Donut）尺寸異常，可用同模式補齊對應 chart component 的 100% 高度規則。
