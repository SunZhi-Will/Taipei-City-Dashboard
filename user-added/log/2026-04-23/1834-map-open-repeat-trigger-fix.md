# 修正地圖開啟無法重複觸發 / Fix Re-trigger Failure for Open Map

## 2026-04-23 18:34

- objective:
  - 修復使用者在 map 頁面無法再次點擊「開啟地圖」以重新勾選同一圖層的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
- summary:
  - 新增 `openTrigger` query（timestamp）使每次點擊「開啟地圖」都能觸發 route query 更新。
  - 調整 auto-open 防重邏輯：僅在「同一組件且圖層已可見」時才跳過，若圖層已被關閉則允許再次啟用。
- change-type:
  - Fixed
- technical-details:
  - `ChatBox.vue` 與 `AIStudioChatPanel.vue`：在 mapview query 附加 `openTrigger: String(Date.now())`。
  - `useMapLayerSidebarContent.js`：
  - 新增 `isComponentVisible(component)`，以 `map_config -> layerId` 對應 `mapStore.currentVisibleLayers` 判斷是否可見。
  - `activateOpenComponent` 的 guard 改為 visibility-aware。
  - `watch` 依賴加入 `route.query.openTrigger`，讓相同 `openComponentId` 可重觸發。
- verification:
  - 問題診斷結果：三個修改檔皆 `No errors found`。
  - 程式檢查：確認存在 `openTrigger` query 與 `isComponentVisible` 判斷。
- performance-impact:
  - 每次開啟地圖僅新增一個 query 參數更新與 watcher 觸發，影響可忽略。
- impact-risk:
  - `openTrigger` 為時間戳，僅用於觸發 watcher，不影響既有查詢邏輯。
  - 若外部流程依賴固定 query 字串比對，需確認不將 `openTrigger` 納入簽名檢查（目前前端內部無此用法）。
- regression-test:
  - 同一組件重複點擊「開啟地圖」至少 3 次，驗證可反覆勾選顯示。
  - 在 map 頁手動取消圖層後，再次由 chat 按「開啟地圖」，驗證可重新啟用。
  - ChatWidget 與 AI Studio 兩入口皆需驗證。
- traceability:
  - previous logs:
  - user-added/log/2026-04-23/1822-map-open-auto-activate-layer.md
  - user-added/log/2026-04-23/1827-map-open-layer-race-fix.md
- next-actions:
  - N/A
