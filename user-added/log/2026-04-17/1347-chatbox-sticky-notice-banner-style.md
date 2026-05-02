# 置頂公告卡片樣式移除與貼齊化 / Remove Card Look from Sticky Notice and Make It Edge-Aligned

## 2026-04-17 13:47

- objective:
  - 將 ChatBox 置頂公告由卡片樣式改為公告條樣式。
  - 移除置頂公告上下左右外距，讓公告貼齊聊天區邊界。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 移除 `.chat-message` 的卡片外觀（padding/margin/border-radius/background）。
  - 將 `.sticky-message` 改為非卡片：
    - 取消外框與圓角
    - 改為僅底線分隔
    - 改為貼齊聊天區邊界（使用負邊距對齊）
  - 調整 sticky 位置使公告固定時仍貼齊上緣。

- change-type:
  - Changed

- technical-details:
  - `.chat-message`:
    - `padding: 0;`
    - `margin: 0;`
    - `border-radius: 0;`
    - `background: transparent;`
  - `.sticky-message`:
    - `margin: -0.75rem -0.75rem 0;`
    - `border: 0;`
    - `border-bottom: 1px solid #ffffff;`
    - `border-radius: 0;`
    - `background: $panel-bg;`
    - `top: -0.75rem;`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，僅 CSS 呈現層調整。

- impact-risk:
  - 低風險，變更範圍限定於置頂公告視覺樣式。
  - 若後續希望回復卡片外觀，可僅調整 `.sticky-message` 區塊。

- regression-test:
  - 開啟 ChatBox，確認置頂公告不再呈現卡片外觀。
  - 確認置頂公告四周無額外間距，貼齊聊天區。
  - 確認展開/收合公告與滾動時 sticky 行為仍正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1343-chatbot-hide-trigger-while-open.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 如需更像系統公告列，可再加上左側 icon 與淡色底，提高辨識度。
