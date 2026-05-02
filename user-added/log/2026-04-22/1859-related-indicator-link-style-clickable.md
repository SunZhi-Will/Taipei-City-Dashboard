# 延伸指標改為可點擊文字連結 / Make Related Indicators Clickable Link-Style Text

## 2026-04-22 18:59

- objective:
  - 將「也可以延伸查看這些相關指標」區塊改為可點擊互動。
  - 呈現由卡片式左右排列改為文字連結風格（類似 `<a>` 下底線）。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將 secondary 指標 UI 從卡片 grid 改為垂直文字連結清單。
  - 每個指標名稱改為底線連結樣式，並保留說明文字。
  - 點擊延伸指標後，會直接觸發新一輪聊天查詢，不需手動輸入。

- change-type:
  - Changed

- technical-details:
  - `ChatResultComponents` 新增 `explore` 事件，點擊 `secondary-link` 會 emit 指標名稱。
  - `ChatBox` 新增 `handleExploreIndicator`，接收事件後呼叫 `addQueryData` 發送查詢。
  - 樣式新增 `secondary-links`、`secondary-link`、`secondary-link-name`，讓名稱呈現可點擊底線效果。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue，結果為 No errors found。
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 以搜尋確認 `@explore="handleExploreIndicator"` 與 `onExplore(comp)` 事件流已建立。

- performance-impact:
  - 僅增加輕量 click 事件轉發，無額外 API 負擔（仍沿用原查詢流程）。

- impact-risk:
  - 若延伸指標名稱過短或過泛，查詢結果可能較廣，需要依內容再優化 query 文案。

- regression-test:
  - 點擊任一延伸指標名稱，確認會立即新增一則 user 訊息並觸發 bot 回覆。
  - 確認延伸區塊為垂直文字連結，不再是左右卡片布局。
  - 確認連結名稱顯示底線，hover 顏色有反饋。

- traceability:
  - Related log: user-added/log/2026-04-22/1853-chat-expand-scroll-and-tag-arrow-fix.md

- next-actions:
  - 若要更像超連結，可再加上鍵盤 focus-visible 樣式與 `Enter` 快捷行為提示。