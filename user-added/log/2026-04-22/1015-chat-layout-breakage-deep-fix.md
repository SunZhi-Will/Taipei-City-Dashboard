# ChatBot 跑板深度修正 / Deep Fix for ChatBot Layout Breakage

## 2026-04-22 10:15

- objective:
  - 修復右下角 ChatBot 在儀表板情境下出現的跑板、裁切與尺寸失衡問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 針對 launcher 面板改為自適應尺寸，避免固定 420x650 在小視窗下超出可視區。
  - 新增低視窗高度（<=760）桌機情境的高度與間距補償。
  - 對 ChatBox 加入樣式隔離，抵抗專案既有全域規則（特別是通配符 overflow/textarea 規則）造成的內容裁切與排版異常。

- change-type:
  - Fixed

- technical-details:
  - 根因分析：
    - 專案中存在高侵入性的全域規則（如 `* { overflow: hidden; }`、`textarea` 全域尺寸），導致聊天元件內部元素在特定路由/視窗尺寸下被裁切或排版錯位。
    - launcher 原本使用固定尺寸（420x650），在低高度螢幕會造成頂部或內容區跑板。
  - 修正實作：
    - ChatWidgetLauncher.vue
      - `.chatbox` 改為 `width: min(420px, calc(100vw - 32px))`
      - `.chatbox` 改為 `height: min(650px, calc(100vh - 96px))`
      - 新增 `@media (max-height: 760px) and (min-width: 769px)`，調整 root offset 與面板高度/間距
    - ChatBox.vue
      - `.chat-widget` 新增 `max-width: 100%`、`height: 100%`、`color` 基準
      - 新增 `box-sizing` 統一規則
      - 對常見容器元素補 `overflow: visible` 隔離，避免受全域 `overflow: hidden` 連帶影響
      - `.chat-area` 補 `min-height: 0`，確保 flex 捲動區穩定
      - `.chat-input` 補 `min-width: 0`、`max-width: none`，解除全域 textarea 規則干擾

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found

- performance-impact:
  - 無新增重型計算；僅 CSS 尺寸計算與樣式隔離，效能影響可忽略。

- impact-risk:
  - 低風險；主要為聊天元件內部樣式調整。
  - 已避免修改既有 dashboard 通配符規則，降低對其他元件的回歸風險。

- regression-test:
  - Desktop: 1920x1080、1366x768、1280x720 下開關聊天面板。
  - 低高度視窗：確認 header/input 不裁切、聊天區可捲動。
  - Mobile (<768)：確認全螢幕面板模式定位與輸入區正常。
  - 路由切換：在 dashboard/mapview 間切換後，launcher 仍固定於右下且尺寸正確。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1009-chat-full-implementation-final.md

- next-actions:
  - N/A
