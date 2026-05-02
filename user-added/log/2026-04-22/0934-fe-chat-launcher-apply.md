# 儀表板右下角聊天元件實際掛載修正 / Apply Right-Bottom Chat on Dashboard FE

## 2026-04-22 09:34

- objective:
  - 將右下角聊天元件確實套用到前端儀表板主應用，而非僅停留在 demo widget。
  - 強化聊天入口在 dashboard/mapview 的可見性與鍵盤可用性。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在 App 主模板中，將 ChatWidgetLauncher 改為僅於 dashboard/mapview 顯示。
  - 在 ChatWidgetLauncher 增加路由切換自動關閉、Esc 僅於開啟時生效、關閉後焦點回到 launcher、開啟後焦點移入 panel。
  - 將 launcher z-index 提升為高層級，避免被地圖或其他 UI 覆蓋。
  - 在 ChatBox panel 增加 tabindex=-1，支援程式化 focus。

- change-type:
  - Fixed

- technical-details:
  - App.vue 新增 computed: shouldShowChatLauncher，條件為 currentPath in [dashboard, mapview]。
  - ChatWidgetLauncher.vue:
    - 新增 route watcher，路由切換時關閉聊天。
    - 新增 launcherButtonRef 以便 close 後回焦。
    - isChatOpen watcher + nextTick 將焦點移至 chat panel。
    - Esc 監聽增加 isChatOpen 保護，避免全域干擾。
    - 固定定位層級 z-index 調高到 2147483000。
  - ChatBox.vue:
    - #chat-widget-panel 新增 tabindex=-1。

- verification:
  - 使用 Problems 檢查以下檔案均為 No errors:
    - Taipei-City-Dashboard-FE/src/App.vue
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - 檔案內容檢查確認：ChatWidgetLauncher 已在 App 中透過 shouldShowChatLauncher 控制顯示。

- performance-impact:
  - 僅新增輕量 watcher 與 focus 控制，效能影響可忽略。

- impact-risk:
  - 低風險；變更僅限聊天元件掛載條件與互動行為，不影響資料流與 API。

- regression-test:
  - 在 /dashboard 與 /mapview 檢查右下角 launcher 是否顯示。
  - 點擊 launcher 展開/收合聊天視窗。
  - 按 Esc 可關閉聊天；關閉後焦點回 launcher。
  - 路由切換後聊天不殘留開啟狀態。

- traceability:
  - N/A

- next-actions:
  - 建議補一個 E2E 測試：驗證 dashboard 右下角 chat 顯示與 Esc 關閉流程。
