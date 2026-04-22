# 移除對話紀錄滑鼠移入變色 / Remove Hover Background Change on Chat Messages

## 2026-04-22 19:02

- objective:
  - 修正聊天對話紀錄在滑鼠移入時背景變色的行為，維持訊息背景一致。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 刪除 `.message:hover` 的背景色樣式，避免滑鼠移到對話紀錄時出現不預期的底色變化。

- change-type:
  - Changed

- technical-details:
  - 移除 `ChatBox.vue` 中 `.chat-area .message` 區塊的 hover 背景設定。
  - 保留其他互動元素（按鈕、tag、連結）的 hover 樣式，不影響操作回饋。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 以檔案內容確認 `.message` 區塊中已無 `&:hover { background: ... }` 設定。

- performance-impact:
  - 無效能影響，僅 UI 樣式刪減。

- impact-risk:
  - 低風險，僅改動訊息列表 hover 視覺，無資料與功能邏輯變更。

- regression-test:
  - 滑鼠移過聊天訊息列表，確認背景不再變色。
  - 確認按鈕與 tag hover 效果仍正常。

- traceability:
  - Related log: user-added/log/2026-04-22/1900-remove-secondary-indicator-description-line.md

- next-actions:
  - N/A