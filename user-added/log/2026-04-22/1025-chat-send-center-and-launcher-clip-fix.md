# 發送鍵置中與右下角裁切修正 / Send Button Centering and Launcher Clip Fix

## 2026-04-22 10:25

- objective:
  - 修正 Chat 輸入欄發送鍵未垂直置中，以及右下角 launcher 圖示在放大/縮放時被切邊問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue

- summary:
  - 發送鍵改為 `top: 50% + translateY(-50%)`，確保在輸入膠囊內垂直置中。
  - hover/active transform 合併 translate，避免互動時位移跳動。
  - launcher 容器與按鈕鏈路明確設為 `overflow: visible`，防止受全域 `* { overflow: hidden; }` 污染而切邊。
  - launcher 定位改為 safe-area aware offset，減少縮放與裝置安全區導致的邊緣裁切。

- change-type:
  - Fixed

- technical-details:
  - ChatBox.vue
    - `.input-shell` 新增 `min-height: 52px` 與 `overflow: visible`
    - `.send-btn` 由 `bottom` 定位改為 `top: 50%; transform: translateY(-50%)`
    - `.send-btn:hover/:active` 改為 `translateY(-50%) scale(...)`
    - mobile send-btn 移除 bottom 依賴，維持中心定位
  - ChatWidgetLauncher.vue
    - `.chat-launcher-root/.chatbot-container/.chatbot-btn-area/.chatbot-btn` 補 `overflow: visible`
    - root 位置改為 `max(..., env(safe-area-inset-*))`
    - 低高度桌機與手機 breakpoint 同步 safe-area offset

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found

- performance-impact:
  - 純 CSS 定位與樣式修正，無新增運算或依賴，效能影響可忽略。

- impact-risk:
  - 低風險；調整限於 Chat 元件，不改動資料流與 API。

- regression-test:
  - 輸入欄單行/多行時發送鍵垂直置中。
  - launcher hover 放大時是否仍完整顯示。
  - 125%/150% 縮放下右下角是否切邊。
  - 手機與低高度桌機位置是否正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1015-chat-layout-breakage-deep-fix.md
    - user-added/log/2026-04-22/1017-chat-sticky-flat-and-color-fix.md

- next-actions:
  - N/A
