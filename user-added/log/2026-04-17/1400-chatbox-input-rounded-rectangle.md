# 輸入欄改為四角圓弧 / Change Input Field to Rounded Rectangle

## 2026-04-17 14:00

- objective:
  - 將下方輸入欄從膠囊形狀改為四角圓弧形狀。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將輸入容器 `.input-shell` 的 `border-radius` 從 `999px` 改為 `14px`。
  - 保留內嵌發送按鈕、多行輸入、Enter 送出與 Shift+Enter 換行行為。

- change-type:
  - Changed

- technical-details:
  - selector: `.chat-widget .input-area .input-shell`
  - before: `border-radius: 999px;`
  - after: `border-radius: 14px;`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，僅視覺樣式調整。

- impact-risk:
  - 低風險，僅輸入容器形狀改變。

- regression-test:
  - 開啟聊天視窗，確認輸入欄為四角圓弧，不再是膠囊形狀。
  - 測試發送按鈕位置與多行輸入行為維持正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1354-chatbox-compact-layout-and-pill-multiline-input.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
