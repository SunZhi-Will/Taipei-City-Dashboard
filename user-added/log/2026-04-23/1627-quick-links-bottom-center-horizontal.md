# 快速連結改為底部置中水平排列 / Quick Links Changed to Bottom-Center Horizontal Layout

## 2026-04-23 16:27

- objective:
  - 將地圖頁左下角的快速連結由垂直堆疊改為底部中間水平排列，以提升視覺平衡與操作效率。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 調整 `.mapcontainer-quick-locations` 定位：由 `left: 12px` 改為 `left: 50% + transform: translateX(-50%)`。
  - 調整排列方式：由 `flex-direction: column` 改為 `row`，並加入 `flex-wrap` 與置中對齊。
  - 擴充容器寬度上限，避免橫向項目過多時擠壓。

- change-type:
  - Changed

- technical-details:
  - CSS 變更集中在 scoped SCSS 的 `.mapcontainer-quick-locations` 區塊。
  - 新增屬性：`transform`, `flex-wrap`, `justify-content`, `align-items`。
  - 將 `max-width` 由 `180px` 調整為 `min(90vw, 860px)`，並在按鈕加上 `white-space: nowrap`。

- verification:
  - 以 VS Code 診斷檢查檔案：`get_errors` 回傳 No errors found。
  - 檔案內容確認：快速連結容器定位與排列屬性已更新為底部置中水平排列。

- performance-impact:
  - 僅樣式層調整，無 JavaScript 執行成本增加。
  - 可能產生輕微重排，但僅限快速連結區塊，整體影響可忽略。

- impact-risk:
  - 低風險；若快速連結數量過多，會在底部換行顯示，可能覆蓋部分地圖視覺區域。
  - 行動版不受影響（原本已由 `hide-if-mobile` 隱藏）。

- regression-test:
  - 驗證桌機地圖頁：快速連結顯示於底部中間且為水平排列。
  - 驗證快速連結增減情境：包含「返回預設」、「新增位置」、個人保存位置與刪除按鈕 hover 行為。
  - 驗證不同視窗寬度下，快速連結是否自然換行且不超出容器。

- traceability:
  - N/A

- next-actions:
  - 若需避免遮擋地圖資訊，可再加上半透明底板或縮小按鈕尺寸並加入橫向捲動。
