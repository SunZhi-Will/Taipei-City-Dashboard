# 地圖交叉頁導覽當前標記修正 / Active Marker Fix for Map Cross-Comparison Navigation

## 2026-04-24 11:33

- objective:
  - 讓使用者在地圖交叉比對頁面可明確辨識目前所在頁籤，避免導覽狀態不明確。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 在地圖頁導覽連結樣式中新增 active/exact-active 狀態視覺標記。
  - 針對當前頁連結加入高亮背景、字重提升與底部白色圓點指示，提升可辨識度。
  - 保留既有 router-link 行為，僅補齊樣式層邏輯，避免影響路由流程。

- change-type:
  - Fixed

- technical-details:
  - 更新 `.map-nav-link`：新增 `position: relative` 以支援指示點定位。
  - 新增 `.map-nav-link.router-link-active, .map-nav-link.router-link-exact-active` 樣式群組。
  - active 樣式包含 `background`, `color`, `font-weight`, `box-shadow`，並透過 `::after` 產生底部指示點。

- verification:
  - 使用 VS Code 診斷檢查：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/MapView.vue`，結果為 No errors found。
  - 檔案檢查：確認 `MapView.vue` 已存在 `router-link-active` / `router-link-exact-active` 對應樣式與 `::after` 指示點。

- performance-impact:
  - 變更僅涉及單一導覽元件 CSS，無資料請求與運算邏輯調整。
  - 預期效能影響可忽略。

- impact-risk:
  - 低風險：僅樣式增補，作用範圍侷限於 `MapView.vue` scoped style。
  - 已知邊界：極小螢幕若導覽膠囊高度不足，底部指示點可能被擠壓，但不影響功能。

- regression-test:
  - 驗證路徑 `/mapview?index=ltc_care_tpe&city=taipei`：地圖交叉比對連結需顯示高亮與指示點。
  - 驗證路徑 `/dashboard?...` 與 `/ai-studio?...`：切換頁面後 active 樣式需隨路由移動。
  - 檢查 hover 與 active 狀態可同時正常顯示，且無文字可讀性問題。

- traceability:
  - log: user-added/log/2026-04-24/1133-mapview-active-nav-marker.md

- next-actions:
  - N/A
