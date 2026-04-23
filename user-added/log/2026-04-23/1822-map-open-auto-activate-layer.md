# 修復開啟地圖未自動啟用圖層 / Fix Open Map Not Auto-Activating Layer

## 2026-04-23 18:22

- objective:
  - 修復 AI Chat 組件卡片點擊「開啟地圖」後，地圖頁未自動啟用目標圖層，導致畫面看似無資料的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
- summary:
  - 在地圖側欄 composable 補回路由 query 同步與自動啟用邏輯。
  - 新增 `route.query.city` 同步到側欄城市切換，避免城市分頁不一致。
  - 新增 `route.query.index/city` 自動展開指定儀表板並載入組件。
  - 新增 `route.query.openComponentId` 監聽，於資料可用時自動呼叫 `mapStore.addToMapLayerList(...)` 並同步勾選狀態。
  - 根因為 MapView 重構為 composable 後，舊版 `.bak` 中的自動啟用流程未完整搬移。
- change-type:
  - Fixed
- technical-details:
  - 於 composable 引入 `useRoute()`，建立三個 `watch(..., { immediate: true })`：
  - 1) `route.query.city`：同步 `selectedPublicCity`。
  - 2) `route.query.index/city`：設定 `expandedDashboardMap` 並呼叫 `ensureDashboardComponents(index)`。
  - 3) `route.query.openComponentId + currentDashboard 依賴`：在找到含 `map_config` 的目標 component 後自動加載圖層與同步 checkbox。
  - 使用 `activatedOpenComponentId` 避免同一 query 重複觸發。
- verification:
  - 指令檢查：對修改檔執行問題診斷，結果 `No errors found`。
  - 檔案檢查：確認 `useMapLayerSidebarContent.js` 已存在 `openComponentId` 監聽與 `mapStore.addToMapLayerList(...)` 呼叫。
  - 行為預期：從 AI Chat 卡片按「開啟地圖」進入 `/mapview?...&openComponentId=...` 時，目標圖層應自動顯示並勾選。
- performance-impact:
  - 僅新增輕量 watcher，對性能影響極低。
  - 透過 `activatedOpenComponentId` 防重入，避免多次重複加載同圖層。
- impact-risk:
  - 若 `openComponentId` 對應組件缺少 `map_config`，仍不會啟圖層（屬預期防呆）。
  - 若後端返回組件延遲，會等資料到齊後再觸發，可能有短暫等待。
- regression-test:
  - 驗證 AI Chat 卡片「開啟地圖」：至少測試 1 個台北、1 個大台北地圖型組件。
  - 驗證手動側欄勾選/取消仍可正常切換圖層。
  - 驗證切換 `/dashboard` ↔ `/mapview` 不應殘留錯誤圖層狀態。
- traceability:
  - related file: Taipei-City-Dashboard-FE/src/views/MapView.vue.bak（歷史可運作邏輯來源）
- next-actions:
  - N/A
