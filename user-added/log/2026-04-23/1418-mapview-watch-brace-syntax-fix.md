# 修正 MapView watch 括號語法錯誤 / Fix MapView Watch Brace Syntax Error

## 2026-04-23 14:18

- objective:
  - 修正 MapView 中 watch 區塊缺少關閉括號，導致 Vue SFC 編譯報 Unexpected token。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 補齊 route.query.index 監聽器 callback 與 watch 呼叫的關閉括號。
  - 調整 activeTab.value = 'theme' 在 if 區塊內，避免語句落在未結束語法區域。

- change-type:
  - Fixed

- technical-details:
  - 受影響段落位於 script setup 前半段（route query watch 後緊接 activateComponentFromChat 函式之前）。
  - 原本缺少 `}` 與 `);`，導致後續函式被解析為未完成區塊內內容。

- verification:
  - 使用 get_errors 檢查：
    - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - 結果：No errors found。

- performance-impact:
  - 無效能影響，純語法修復。

- impact-risk:
  - 低風險：僅調整括號與區塊界線，不變更既有業務流程。

- regression-test:
  - 啟動前端後進入 mapview 頁面，確認頁面可正常載入且無白屏。
  - 從聊天點「開啟地圖」，確認導頁後可進入地圖頁。

- traceability:
  - Related logs:
    - user-added/log/2026-04-23/1407-地圖型組件聊天顯示修正-map-component-chat-render-fix.md
    - user-added/log/2026-04-23/1414-聊天地圖卡重複與自動啟動修正-chat-map-open-activation-fix.md

- next-actions:
  - N/A
