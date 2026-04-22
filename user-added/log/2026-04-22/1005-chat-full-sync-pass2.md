# 聊天元件全面同步（第二輪） / Chat Widget Full Sync Pass 2

## 2026-04-22 10:05

- objective:
  - 依「全面同步」要求，將 Vue Chat 的視覺與交互進一步貼齊 aichathub chatbot。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - Launcher：加入 pointer-events 隔離、面板展開動畫、active 狀態、RWD 斷點調整為 768。
  - Panel：訊息進場動畫、typing dots 回應中狀態（取代純文字）、輸入框 placeholder/focus 視覺、send button active。
  - Mobile：浮層與按鈕尺寸進一步貼近 aichathub 行為。

- change-type:
  - Changed

- technical-details:
  - ChatWidgetLauncher.vue:
    - .chat-launcher-root 新增 pointer-events: none
    - .chatbot-container 新增 pointer-events: auto
    - .chatbox 新增 chat-panel-in 動畫
    - .chatbot-btn 新增 active feedback
    - media query 由 600 改 768，並同步底部/右側間距
  - ChatBox.vue:
    - isResponding 區塊改為 typing-dots + typing-dot 三點動畫
    - .message 新增 chat-msg-in 動畫
    - .chat-input 新增 placeholder 與 focus 邊框狀態
    - .send-btn 新增 active 狀態
    - 新增 keyframes: chat-msg-in, chat-typing-bounce

- verification:
  - Problems 檢查均為 No errors:
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
    - Taipei-City-Dashboard-FE/src/App.vue

- performance-impact:
  - 僅新增輕量 CSS 動畫與狀態樣式，影響可忽略。

- impact-risk:
  - 中低風險；視覺改動較多，需實際驗收桌機/手機樣式是否符合預期。

- regression-test:
  - launcher hover/active 與開關動畫。
  - panel 訊息進場動畫與回應中三點動畫。
  - input focus/placeholder/送出按鈕狀態。
  - 768 以下版面定位與高度。

- traceability:
  - related-log: user-added/log/2026-04-22/1001-chat-style-cross-validation-and-alignment.md

- next-actions:
  - 若要 1:1 像素對齊，可再微調 header/icon/table/間距細節。
