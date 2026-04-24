# AI Studio 圖表自適應縮放修正 / AI Studio Chart Responsive Resize Fix

## 2026-04-24 13:10

- objective:
  - 修正 AI Studio 圖表在模式切換或全螢幕切換後未依容器重新縮放的問題。
  - 移除圖表牆固定高度 320px 導致的尺寸僵化。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 新增畫布尺寸重算觸發機制：當模式、沉浸狀態、圖表數量變化時，主動觸發 resize。
  - map 模式同步呼叫 mapbox `resize()`，避免地圖容器尺寸不同步。
  - 圖表牆卡片高度改為響應式計算值，取代固定 320px。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 `componentCardHeight` computed：
    - immersive: `min(52vh, 560px)`
    - normal: `clamp(260px, 36vh, 460px)`
  - 新增 `triggerCanvasResize()`：
    - `nextTick` + `requestAnimationFrame` 後觸發 `window.resize`。
    - 若 map 已初始化，執行 `mapStore.map.resize()`。
  - 新增 watch 監聽：`selectedMode`、`isImmersive`、`componentCards.length`，在 UI 變化後重算尺寸。

- verification:
  - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/AIStudioView.vue` → No errors found。
  - 代碼檢查確認已補 `nextTick` import 並正確使用。

- performance-impact:
  - 額外 resize 事件僅在模式/狀態變更時觸發，頻率低。
  - 可顯著降低圖表顯示尺寸錯誤造成的重繪與使用者重操作成本。

- impact-risk:
  - 低風險：變更集中在 AI Studio 視圖層，不改後端與資料流程。
  - 邊界：若第三方圖表元件對 resize 事件有節流需求，後續可再補 debounce。

- regression-test:
  - 切換「輪播 / 圖表牆 / 地圖」檢查圖表是否會跟容器正確縮放。
  - 切換全螢幕進出，檢查圖表與地圖是否即時貼合容器。
  - 調整瀏覽器視窗大小，確認圖表高度不再固定於 320px。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍有個別圖表（特定 Apex 類型）縮放延遲，可對該圖型再補局部 `ResizeObserver`。
