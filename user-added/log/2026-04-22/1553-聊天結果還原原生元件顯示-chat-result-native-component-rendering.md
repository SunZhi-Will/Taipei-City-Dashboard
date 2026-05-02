# 聊天結果還原原生元件顯示與程式拆分 / Restore Native Dashboard Rendering In Chat And Split Renderer Logic

## 2026-04-22 15:53

- objective:
  - 修正 Chat 中 Agent + RAG 搜尋結果顯示與原始儀表板元件外觀不一致的問題。
  - 將聊天結果渲染邏輯拆分為獨立子元件，降低 `ChatBox.vue` 複雜度。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 新增「結果渲染子元件」：把原本內嵌在 `ChatBox.vue` 的 component-card 顯示邏輯搬移到 `ChatResultComponents.vue`。
  - 聊天結果若為 `dashboard_component`，改為以 `DashboardComponent` (`mode=preview`) 原生渲染，不再只用通用白底卡片。
  - 在 `chatStore` 新增 hydration：由 `/vector/component` 取得 `id` 後，補抓 `/component/:id/all`，依 city 選擇對應 config，注入 `dashboardConfig` 供原生渲染。
  - 保留回退策略：若無法取得完整 config，仍顯示通用卡片，避免 UI 中斷。

- change-type:
  - Changed

- technical-details:
  - `chatStore.js`:
    - 新增 `pickConfigByCity()` 與 `hydrateDashboardComponents()`。
    - 在 Agent 使用 `retrieve_components_by_query` 且走向量 fallback 時，將結果轉成包含 `dashboardConfig` 的結構。
  - `ChatResultComponents.vue`:
    - 依 `category` 與 `dashboardConfig` 判斷顯示模式。
    - `dashboard_component + dashboardConfig`：使用 `DashboardComponent` 原生預覽。
    - 其他類型：保留通用資訊卡（名稱/分類/描述/props/示例）。
  - `ChatBox.vue`:
    - 改為掛載 `ChatResultComponents`，移除舊的內嵌 component-card 區塊。
    - 清理舊 component-card 相關樣式，避免樣式衝突。
    - 修復本次調整過程中造成的結構損壞（補回 `<script>`, `<template>` 正確邊界）。

- verification:
  - `get_errors` 檢查以下檔案皆為 No errors found：
    - `Taipei-City-Dashboard-FE/src/store/chatStore.js`
    - `Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue`
    - `Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue`
  - API 路徑驗證：
    - `POST /api/dev/vector/component` 回應 200。
    - `GET /api/dev/component/214/all` 可取得完整組件設定資料（包含 chart_config 與 city）。

- performance-impact:
  - 相較舊版，`dashboard_component` 結果會追加 detail hydration 請求（每個項目一次 `/component/:id/all`）。
  - 目前 `limit=5`，可接受；如需再優化可改批次端點或本地快取。

- impact-risk:
  - 風險等級：中低。
  - 風險來源：若 detail endpoint 短暫失敗，會回退到通用卡片而非原生元件。
  - 緩解方式：已保留 fallback，不會阻斷聊天流程。

- regression-test:
  - [ ] 查詢「扶養比及老化指數」，確認顯示為原生 `DashboardComponent` 預覽而非白底通用卡。
  - [ ] 查詢無法 hydration 的案例，確認仍顯示 fallback 通用卡。
  - [ ] 檢查聊天展開/收合後結果仍可正確顯示。

- traceability:
  - related-log: `user-added/log/2026-04-22/1615-ai-component-result-fix.md`
  - related-log: `user-added/log/2026-04-22/1600-dashboard-search-card-ui.md`

- next-actions:
  - P1: 若要 100% 與主頁一致，可在 BE 新增批次 detail 端點，減少前端 N 次 hydration 呼叫。
  - P2: 將展開模式（full-screen）也切到同一個 `ChatResultComponents`，保持雙視圖一致性。
