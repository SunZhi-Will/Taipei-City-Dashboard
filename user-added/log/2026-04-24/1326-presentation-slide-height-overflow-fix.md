# 輪播高度溢出與內容偏移修正 / Presentation Slide Height Overflow and Content Offset Fix

## 2026-04-24 13:26

- objective:
  - 修正 AI Studio 輪播中組件卡片內容高度超出，造成圖表顯示不完整。
  - 修正 TextUnitChart 在輪播中的視覺偏移，避免內容看起來整體下沉。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TextUnitChart.vue

- summary:
  - 將輪播圖表容器從固定 `height: 100%` 改為 `flex: 1 + min-height: 0`，使其僅占用標題區塊以外的剩餘空間。
  - 調整 TextUnitChart 容器高度策略，改為填滿父層並移除內部捲動，改善版面垂直對齊與裁切問題。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `AIStudioPresentationCanvas.vue`
    - `.chart-glass-base`:
      - `height: 100%` -> `flex: 1`
      - 新增 `min-height: 0`
    - 修正後可避免 `slide-component-meta + chart-glass-base(100%)` 疊加超高。
  - `TextUnitChart.vue`
    - `.TextUnitChart`:
      - `overflow-y: auto` -> `overflow: hidden`
    - `.TextUnitChart__container`:
      - 新增 `height: 100%`
      - 保留 `min-height: 100%`
      - 新增 `align-content: stretch`

- verification:
  - 使用 `get_errors` 檢查：
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TextUnitChart.vue -> No errors found
  - 結構驗證重點：圖表容器高度改為剩餘空間分配，不再與上方 meta 區塊相加超出。

- performance-impact:
  - 僅為 CSS 佈局調整，無新增網路請求或計算負擔。
  - 移除不必要內部滾動後，渲染與交互體驗更穩定。

- impact-risk:
  - 低風險。影響範圍集中在輪播展示模式與 TextUnitChart 排版。
  - 若外層父容器高度未定義，可能仍出現布局不一致；現有畫面已有固定高度鏈可承接。

- regression-test:
  - 驗證 AI Studio 輪播中含標題/副標題的組件頁，圖表不再被底部裁切。
  - 驗證 TextUnitChart（長照指標）四格內容視覺置中，不再明顯下沉。
  - 驗證其他圖表在輪播中仍可正常撐滿顯示區。

- traceability:
  - N/A

- next-actions:
  - P1: 如仍有個別圖型（例如 DistrictChart）在特定資料量下擠壓，可補一輪「各圖型 presentation 專屬高度策略」一致化。