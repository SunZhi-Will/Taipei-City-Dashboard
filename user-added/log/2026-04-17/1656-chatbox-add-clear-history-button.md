# 新增聊天視窗清除歷史按鈕 / Add Clear Chat History Button to ChatBox

## 2026-04-17 16:56

- objective:
  - 在聊天視窗加入垃圾桶按鈕（🗑️），用戶可一鍵清除聊天歷史並開新 Chat。
  - 使用確認對話避免誤操作。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在 chatStore 新增 `clearChatHistory()` 方法，重置聊天資料並清空 sessionStorage。
  - 在 ChatBox header 新增清除按鈕（垃圾桶 emoji），放在關閉按鈕左側。
  - 按鈕觸發前先確認，確保使用者不會誤觸。
  - 更新 header 樣式以支援多個按鈕排列（.header-actions 容器）。

- change-type:
  - Added

- technical-details:
  - store:
    - `clearChatHistory()` 函式：
      - `chatData.value = [...defaultChatData]`：重置為預設訊息
      - `sessionStorage.removeItem('chatData')`：清空持久化儲存
      - `isResponding.value = false`：中止任何回應狀態
    - 在 export return 中新增 `clearChatHistory`
  - component:
    - script:
      - 導入 `clearChatHistory` 方法
      - 新增 `clearChat()` 函式，附帶確認對話
    - template:
      - header 新增 `<div class="header-actions">` 容器
      - 清除按鈕使用垃圾桶 emoji：`🗑️`
      - 保持原有關閉按鈕
    - style:
      - 重構 `.header` 為更完整的 flexbox 佈局
      - 新增 `.header-actions` 容器（flex gap 0.5rem）
      - 新增 `.action-btn` 通用樣式（28x28 圓形、邊框、hover 效果）
      - `.clear-btn` 與 `.close-btn` 繼承 `.action-btn`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/store/chatStore.js -> No errors found

- performance-impact:
  - 無額外性能影響，僅在清除時重置陣列與清空儲存。

- impact-risk:
  - 低風險。
  - 使用者可能誤觸，但有確認對話保護。
  - 清除動作是可逆的（重新開始後重新問問題）。

- regression-test:
  - 驗證垃圾桶按鈕在 header 右側正確顯示。
  - 驗證點擊垃圾桶按鈕彈出確認對話。
  - 驗證確認後聊天歷史清除，僅留預設訊息。
  - 驗證 sessionStorage 的 chatData 被清空。
  - 驗證關閉按鈕仍正常工作。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1550-chatbox-desktop-size-and-spacing.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
