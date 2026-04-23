# 聊天地圖卡重複與自動啟動修正 / Chat Map Card Duplication and Activation Fix

## 2026-04-23 14:14

- objective:
  - 修正聊天推薦中地圖型組件出現重複區塊（地圖卡 + 一般卡）問題。
  - 修正「開啟地圖」僅導頁但未自動啟動對應圖層的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 將聊天主卡渲染改為互斥鏈（v-if / v-else-if / v-else），避免同一筆地圖資料重複顯示兩塊卡片。
  - 開啟地圖時帶入 openComponentId query。
  - 在 mapview 監聽 openComponentId，於資料可用後自動呼叫 mapStore.addToMapLayerList 流程並同步 toggle 狀態。

- change-type:
  - Fixed

- technical-details:
  - ChatResultComponents:
    - 第二段渲染條件由 v-if 改為 v-else-if，讓地圖卡、圖表預覽卡、一般卡互斥。
  - ChatBox:
    - handleOpenMap 新增 openComponentId（取自 component.dashboardConfig.id）並放入 mapview query。
  - MapView:
    - 新增 activatedOpenComponentId 防重複啟動。
    - 新增 activateComponentFromChat(componentId)；依當前是否 map-layers dashboard，對 mapLayer/hasMap 分支進行自動啟用與 toggle 同步。
    - 新增 watch 監聽 route.query.openComponentId 與內容載入狀態，資料就緒即啟動。

- verification:
  - 使用 VS Code diagnostics 檢查以下檔案：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
    - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - 結果皆為 No errors found。

- performance-impact:
  - 只新增輕量 watch 與一次性啟動判斷，無新增輪詢。
  - 透過 activatedOpenComponentId 防止重複觸發，效能影響低。

- impact-risk:
  - 低至中風險：涉及 mapview 初始化與聊天跨頁互動。
  - 邊界：若 query.openComponentId 對應資料不存在於當前 dashboard，將不會自動啟動圖層（保持安全不誤開）。

- regression-test:
  - 地圖型聊天推薦僅出現一個主卡（無重複一般卡）。
  - 點「開啟地圖」後導向 /mapview 並自動開啟對應圖層。
  - 一般圖表型推薦維持原有預覽行為。

- traceability:
  - Related log: user-added/log/2026-04-23/1407-地圖型組件聊天顯示修正-map-component-chat-render-fix.md

- next-actions:
  - P1: 若 openComponentId 未命中，增加回退策略（用 index/name 嘗試定位）。
