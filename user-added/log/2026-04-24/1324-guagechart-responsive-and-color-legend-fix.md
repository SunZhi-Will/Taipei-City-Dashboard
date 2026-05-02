# 量表圖輪播放大與顏色圖例修正 / GuageChart Carousel Scaling and Color Legend Fix

## 2026-04-24 13:24

- objective:
  - 修正輪播中 GuageChart（量表圖）未隨容器放大的問題。
  - 為輪播場景補上顏色對應說明，讓使用者可理解顏色語意。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/GuageChart.vue

- summary:
  - 將 GuageChart 從固定 `width="80%" + height="300px"` 改為 `100% x 100%` 響應式。
  - Apex chart 設定新增父容器重繪能力，避免輪播切換後尺寸殘留。
  - 新增輪播顏色圖例（自定義 legend），並在啟用時隱藏 Apex 內建 legend 避免重複。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 prop `showColorLegend`。
  - `chartOptions.chart` 新增：
    - `width: "100%"`
    - `height: "100%"`
    - `redrawOnParentResize: true`
    - `redrawOnWindowResize: true`
  - 新增 `guageLegendItems` computed：
    - 若有 `chart_config.categories`，使用 categories + color 對應。
    - 否則以 `series[0].name` 作主色，並補「其餘」對應 track 灰色。
  - 新增 `guagechart` scoped style：
    - 強制 apex wrapper/canvas/svg 100% 尺寸
    - `showColorLegend` 時隱藏內建 `.apexcharts-legend`
    - 增加底部半透明圖例膠囊

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/GuageChart.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 主要為樣式與顯示邏輯調整，無新增 API 請求。
  - 重繪觸發僅在父容器/視窗變更時，成本可接受。

- impact-risk:
  - 低至中風險：GuageChart 在一般頁面也改為 100% 尺寸，若父容器高度設置異常可能放大過度。
  - 已以現有 DashboardComponent 高度管理吸收風險。

- regression-test:
  - 驗證 AI Studio 輪播中的 YouBike 量表圖可放大填滿可用區。
  - 驗證顏色圖例可顯示「主指標 / 其餘」或多分類對應。
  - 驗證一般儀表板頁的量表圖仍正常顯示。

- traceability:
  - N/A

- next-actions:
  - P1: 若你同意，可把同樣的 custom legend 機制擴到 PolarArea/Bar/Column，做到所有輪播圖型一致。
