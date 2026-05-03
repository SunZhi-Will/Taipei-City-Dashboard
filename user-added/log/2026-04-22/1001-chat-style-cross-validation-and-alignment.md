# 聊天樣式交互驗證與對齊 / Chat Style Cross-Validation and Alignment

## 2026-04-22 10:01

- objective:
  - 交互驗證目前 Vue Chat 樣式與 aichathub chatbot 樣式的一致性。
  - 將主要視覺語言（launcher/panel/header/message/input）對齊至 aichathub 風格。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - Launcher 尺寸、圓角、陰影、hover motion、定位間距改為貼近 aichathub。
  - 聊天面板尺寸調整為 420x650，加入 16px 圓角與對應陰影。
  - Header 高度與按鈕狀態風格調整為 aichathub 深色頂欄。
  - Message 區改為淺色基底，使用者訊息泡泡改深色；bot 內容改深字。
  - Input 區改為圓角長條（52px 起）、44px 發送按鈕與對應陰影/hover。
  - 手機版調整為更接近 aichathub 的全高浮層樣式。

- change-type:
  - Changed

- technical-details:
  - ChatWidgetLauncher:
    - root bottom/right 改 24px
    - chatbox 改 420x650
    - launcher 改 56x56，hover 動畫與陰影對齊
    - mobile 尺寸與邊距同步調整
  - ChatBox:
    - 色彩 token 由深色主題轉為 aichathub 淺底 + 深色 header
    - panel/header/message/input 多處 spacing、border、radius、shadow 對齊
    - send button 由 30x30 調整到 44x44

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue: No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue: No errors found
  - 交互對照基準：
    - widget-demo-clean/aichathub-widget-v2.js 的 launcher/panel/header/input CSS 規格

- performance-impact:
  - 僅 CSS 視覺層調整，效能影響可忽略。

- impact-risk:
  - 中低風險；可能影響既有深色聊天視覺習慣，但功能行為不變。

- regression-test:
  - 右下角 launcher 顯示、hover、點擊展開/收合。
  - panel 尺寸與滾動行為。
  - 使用者訊息與 bot 訊息可讀性。
  - 輸入框多行與送出按鈕狀態。
  - mobile viewport 版面定位與高度。

- traceability:
  - reference: widget-demo-clean/aichathub-widget-v2.js

- next-actions:
  - 若需 1:1 完全像素對齊，可再做第二輪微調（字級/間距/動畫 timing）。
