# 置頂公告貼齊上方並移除左右間距 / Sticky Notice Attached to Top Without Side Gaps

## 2026-04-22 10:52

- objective:
  - 依需求將上方置頂公告左右間距移除，並貼齊上方區塊。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 置頂公告移除左右 margin，改為滿寬貼齊聊天區。
  - 聊天區頂部 padding 由 1rem 改為 0，讓公告緊貼 header 下方。

- change-type:
  - Changed

- technical-details:
  - `.chat-area`
    - `padding: 1rem 0 0.5rem` -> `padding: 0 0 0.5rem`
  - `.sticky-message`
    - `margin: 0 1rem 0.75rem` -> `margin: 0 0 0.75rem`

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，僅版面間距調整。

- impact-risk:
  - 低風險；僅影響公告區塊位置與間距。

- regression-test:
  - 置頂公告在展開/收合時仍正常顯示。
  - 公告與上方 header 的貼齊效果符合需求。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1032-chat-sticky-text-color-regression-fix.md

- next-actions:
  - N/A
