# 移除 Chat Bot 縮小與恢復按鈕 / Remove Chat Bot Minimize and Restore Buttons

## 2026-04-17 13:41

- objective:
  - 依需求移除右下角 Chat Bot 的「縮小」與「開啟小幫手」按鈕。
  - 保留單一聊天主按鈕，簡化操作介面。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue

- summary:
  - 刪除 `hide-chat-btn`（縮小按鈕）與 `chat-restore-btn`（開啟小幫手按鈕）模板。
  - 移除 `isLauncherVisible` 狀態及 `dismissLauncher`、`restoreLauncher` 邏輯。
  - 移除 localStorage 隱藏/恢復機制，聊天入口改為固定存在。
  - 保留聊天主按鈕開關與 `Esc` 關閉行為。

- change-type:
  - Changed

- technical-details:
  - 移除常數 `CHAT_WIDGET_HIDDEN_KEY`。
  - `toggleChat()` 不再依賴 launcher 可見狀態判斷。
  - `onMounted()` 僅保留鍵盤事件註冊。
  - 清理相關 CSS：`.hide-chat-btn`、`.chat-restore-btn`。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found

- performance-impact:
  - 小幅降低狀態與 DOM 節點數量，無負面效能影響。

- impact-risk:
  - 介面行為改變：使用者無法再隱藏整個聊天入口。
  - 但符合需求，且可避免誤隱藏後找不到入口。

- regression-test:
  - 測試聊天主按鈕開啟/收合視窗。
  - 測試 `Esc` 關閉聊天視窗。
  - 測試手機版位置與開關行為。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1324-chatbot-ui-split-p0-implementation.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 若要更簡潔，可評估移除 ChatBox 右上角關閉按鈕，只保留主按鈕開關。
