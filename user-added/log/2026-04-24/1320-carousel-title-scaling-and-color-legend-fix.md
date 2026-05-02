# 輪播標題、縮放一致性與顏色對應修正 / Carousel Title, Scaling Consistency, and Color Legend Fix

## 2026-04-24 13:20

- objective:
  - 修正輪播中「標題不見」問題。
  - 修正輪播中「只有部分圖表放大、部分仍小尺寸」的不一致問題。
  - 增加輪播圖表顏色對應說明，避免使用者無法辨識顏色代表項目。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue

- summary:
  - 在輪播 component slide 新增外層標題與副標題區塊（`slide-component-meta`）。
  - 新增 `presentationMode` 到 DashboardComponent，輪播內統一走 presentation 版型，確保內容區高度與縮放規則一致。
  - DonutChart 新增輪播顏色圖例（顏色點 + 類別名稱），對應每個 slice 的 label 與 color。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `AIStudioPresentationCanvas.vue`:
    - 在 component slide 的 chart 區上方新增 `slide-component-title` 與 `slide-component-subtitle`。
    - 傳入 `:presentation-mode="true"` 給 DashboardComponent。
  - `DashboardComponent.vue`:
    - 新增 prop: `presentationMode`。
    - root class 增加 `presentation`，在 scoped style 裡統一：
      - 隱藏 header/control/footer
      - chart/loading/error 高度改為 100%
      - chart 子元素高度強制 100%
  - `DonutChart.vue`:
    - 新增 prop `showColorLegend`。
    - 依 `parsedLabels` + `chart_config.color` 建立 `donutLegendItems`。
    - 新增 `donutchart-legend` UI，顯示每個顏色對應的類別名稱。

- verification:
  - `get_errors`：
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue -> No errors found

- performance-impact:
  - presentationMode 透過簡化子區塊（隱藏 header/control/footer）減少不必要渲染。
  - Donut legend 增加少量 DOM，但成本低，換取顏色語意可讀性提升。

- impact-risk:
  - 中低風險：`presentationMode` 預設 false，不影響一般儀表板頁。
  - 顏色圖例目前先由 DonutChart 支援；其他 chart 類型若需同級圖例可後續擴充。

- regression-test:
  - 進入 AI Studio 輪播確認每張 component slide 均有標題與副標。
  - 測試不同類型圖表在輪播中是否都吃滿可用內容區。
  - 測試 Donut 圖表是否出現「顏色 -> 類別」圖例。

- traceability:
  - N/A

- next-actions:
  - P1: 若你要，我可把同樣的「顏色對應圖例」擴到 PolarArea / Bar / Column 等圖型。
