# 移除 Chat 區塊 margin 0.25rem / Remove Chat Area margin 0.25rem

## 2026-04-17 13:50

- objective:
  - 依需求移除 Chat 區塊的 `margin: 0.25rem;`。
  - 讓聊天內容區與外層版面貼齊，不保留額外外距。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在 `.chat-area` 樣式中刪除 `margin: 0.25rem;` 宣告。
  - 其餘 padding、sticky 公告與訊息樣式保持不變。

- change-type:
  - Changed

- technical-details:
  - 變更點：`.chat-widget .chat-area`。
  - 移除屬性：`margin: 0.25rem;`。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，僅 CSS 版面微調。

- impact-risk:
  - 低風險，僅調整聊天區外距。
  - 可能帶來視覺差異：內容更貼齊邊界（符合需求）。

- regression-test:
  - 打開 ChatBox 檢查聊天區四周不再有 0.25rem 外距。
  - 確認置頂公告 sticky 行為正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1347-chatbox-sticky-notice-banner-style.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
