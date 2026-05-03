# App UI 滾動增強 / App UI Scroll Enhancement

## 2026-04-22 13:44

- objective:
  - 修復 app-content-body 與 dashboard 容器的滾動行為
  - 移除 dashboard 的固定高度限制以支援動態內容

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 在 App.vue 的 `.app-content-body` 中新增 `overflow-y: auto` 屬性以啟用垂直滾輪
  - 在 DashboardView.vue 的 `.dashboard` 中移除兩個 `max-height` 限制設定（移除 `calc(100vh - 127px)` 與 `calc(var(--vh) * 100 - 127px)`）
  - 將 `.dashboard` 的 `overflow-y` 從 `scroll` 改為 `auto`
  - 調整後容器將能更自然地適應內容高度並提供滾輪支援

- change-type:
  - Changed

- technical-details:
  - `.app-content-body` 添加 `overflow-y: auto` 使其在超出視口時自動顯示滾輪
  - `.dashboard` 移除固定的 `max-height` 計算公式，改用 `overflow-y: auto` 自動計算高度
  - 此改動保持 flexbox 和 grid 佈局的完整性
  - 滾動行為改為需要時才顯示（`auto`），而非始終顯示（`scroll`）

- verification:
  - [ ] 在瀏覽器中檢查 dashboard 頁面是否正常顯示
  - [ ] 測試當內容超出視口時滾輪是否出現
  - [ ] 驗證響應式布局在各斷點（720px, 1296px, 1800px, 2200px）是否正常
  - [ ] 檢查 Firefox, Chrome, Safari 中的滾輪顯示

- impact-risk:
  - 影響範圍：所有使用 dashboard view 的頁面和 app-content-body 容器的路由
  - 風險：可能影響頁面高度計算和動畫效果（若有相依），應檢查其他 JavaScript 中的高度相關邏輯
  - 邊界情況：內容不超出視口時應無滾輪顯示；超出時滾輪自動出現

- regression-test:
  - [ ] 儀表板檢視 (DashboardView)
  - [ ] 行政檢視 (AdminView)
  - [ ] 地圖檢視 (MapView)
  - [ ] 組件檢視 (ComponentView)
  - [ ] 手機裝置 (max-width: 760px)
  - [ ] 平板裝置 (768px - 1024px)
  - [ ] 桌面裝置 (1025px+)

- traceability:
  - N/A

- next-actions:
  - 若滾輪顯示後有視覺問題，檢查其他 CSS 中的 overflow 或 height 限制
  - 監控用戶反饋關於滾動體驗的改善
