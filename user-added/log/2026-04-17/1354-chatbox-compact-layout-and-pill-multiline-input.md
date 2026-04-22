# ChatBox 簡約高度與膠囊多行輸入框 / Compact ChatBox Layout and Pill Multiline Input

## 2026-04-17 13:54

- objective:
  - 將 ChatBox 上下區塊高度縮小並簡約化。
  - 將下方輸入區改為「膠囊形多行輸入框 + 內嵌發送按鈕」，接近 ChatGPT 的輸入體驗。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 上方 header 降低高度：減少 padding、邊框由粗線改細線、標題字級下調。
  - 下方 input-area 降低高度：減少 padding 並加上細分隔線。
  - 輸入區改成 `textarea`（多行），按鍵行為：
    - `Enter` 送出
    - `Shift+Enter` 換行
  - 新增自動高度調整（autosize），最大高度限制 120px。
  - 發送按鈕改為內嵌在膠囊輸入框右下角。

- change-type:
  - Changed

- technical-details:
  - script:
    - 新增 `chatInputRef`。
    - 新增 `resizeInput()`、`onInputChange()`、`onInputKeydown()`。
    - `sendBtnHandler()` 送出後清空內容並重算輸入框高度。
  - template:
    - `input` 改為 `textarea`。
    - 新增 `.input-shell` 包裹輸入區，`send-btn` 放入其內。
    - `send-btn` disabled 條件擴充為 `isResponding || !userMessage.trim()`。
  - style:
    - `.header`：`padding: 0.625rem 0.875rem`、`border-bottom: 1px`、`h3` 改 16px。
    - `.input-area`：縮小為 `padding: 0.625rem 0.75rem`。
    - `.input-shell`：膠囊外形 `border-radius: 999px`。
    - `.chat-input`：多行、可自動增高、禁用手動 resize。
    - `.send-btn`：絕對定位於輸入框內。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 輸入框 autosize 增加極小量 reflow，僅在輸入事件觸發，影響可忽略。

- impact-risk:
  - 行為改變：使用者需用 `Shift+Enter` 才能換行。
  - 若使用者習慣 Enter 換行，需透過 placeholder 引導（已補提示字）。

- regression-test:
  - 驗證 Enter 可送出、Shift+Enter 可換行。
  - 驗證輸入超過一行時高度自動增加且不超過 120px。
  - 驗證發送中 disabled 與空白內容 disabled。
  - 驗證上下區塊視覺高度確實縮小。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1347-chatbox-sticky-notice-banner-style.md
    - user-added/log/2026-04-17/1350-chatbox-remove-chat-area-margin.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 若要更貼近 ChatGPT，可改用純箭頭上送圖示（深底白箭頭）取代現有 SendIcon。
