# 右下角 Chat Bot 拆分與 P0 體驗補強 / Chat Bot Split and P0 UX Hardening

## 2026-04-17 13:24

- objective:
  - 將 App 內嵌的 Chat Bot 區塊拆分為獨立元件，降低耦合並提升可維護性。
  - 一次實作 P0 UX 修正：可恢復入口、可及性標記、發送中狀態、防重複送出、手機可用。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 將原本寫在 App 的聊天啟動器/按鈕/定位樣式抽離到新檔 `ChatWidgetLauncher.vue`。
  - 新增可恢復機制：使用者隱藏小幫手後，仍可用「開啟小幫手」按鈕復原入口，不再永久消失。
  - 新增鍵盤行為：按 `Escape` 可關閉聊天視窗。
  - 手機版不再直接隱藏 Chat Bot，改為保留浮動入口，並在開啟時使用較適合的小螢幕定位。
  - `ChatBox.vue` 補上 dialog/log 語意與 aria 屬性，並新增可選關閉按鈕（由 launcher 控制）。
  - `chatStore.js` 新增 `isResponding` 狀態，送出中會鎖定輸入與按鈕，避免重複送出。
  - 移除 AI 回覆前綴 `[Agent]/[Agent+RAG]`，改由現有 UI 模式膠囊顯示，降低重複資訊。

- change-type:
  - Changed

- technical-details:
  - `App.vue`:
    - 移除 `isChatBtnShow`、`isChatBoxShow`、`chatbotBtnHandler`、`hideBtnClickHandler`。
    - 刪除舊 chatroom style block 與 mobile `display:none` 規則。
    - 改為掛載 `<ChatWidgetLauncher />`。
  - `ChatWidgetLauncher.vue`:
    - 新增 `CHAT_WIDGET_HIDDEN_KEY`，以 localStorage 保存隱藏狀態。
    - 新增 `dismissLauncher()`、`restoreLauncher()`、`toggleChat()`、`closeChat()`。
    - 新增 `aria-label`、`aria-expanded`、`aria-controls`。
    - 行動裝置樣式調整為可開啟聊天視窗（非完全隱藏）。
  - `ChatBox.vue`:
    - 新增 `showCloseButton` prop 與 `close` emit。
    - 新增 `role="dialog"`、對話區 `role="log"` + `aria-live="polite"`。
    - 新增輸入區 disabled 狀態、發送按鈕 disabled 狀態、回應中提示 `小幫手回應中...`。
  - `chatStore.js`:
    - 新增 `isResponding` ref。
    - `addQueryData` 進入請求時 `isResponding=true`，離開時 `finally` 還原。
    - 防止發送中重入，避免短時間重複送出。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/App.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/store/chatStore.js -> No errors found
  - 靜態檢查:
    - 已確認聊天入口從 App 成功拆分至獨立元件。
    - 已確認 launcher 與 chatbox 的 close/open 事件鏈路完整。

- performance-impact:
  - 對渲染效能影響低，主要是元件拆分與狀態管理調整。
  - `isResponding` 鎖定可降低重複請求，預期能減少無效 API 負載。

- impact-risk:
  - 主要風險在聊天互動流程（開關/隱藏/復原）行為改變，需要實機快速驗證。
  - localStorage 若被手動清除，僅影響是否預設顯示入口，不影響功能可用性。

- regression-test:
  - 測試聊天入口：開啟、收合、隱藏、復原。
  - 測試鍵盤：`Escape` 可關閉 chat box。
  - 測試送出流程：發送中輸入框與按鈕應禁用，完成後恢復。
  - 測試手機寬度（<=600px）：入口可見，聊天窗可開啟。

- traceability:
  - related-analysis:
    - 右下角 Chat Bot UIUX 深度分析（本回合前置分析）
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P0: 補上焦點陷阱（focus trap）與開啟後自動聚焦輸入框。
  - P1: 加入發送失敗重試按鈕與錯誤訊息層級（inline + toast）。
  - P1: 進一步優化手機版為底部抽屜（bottom sheet）互動。
