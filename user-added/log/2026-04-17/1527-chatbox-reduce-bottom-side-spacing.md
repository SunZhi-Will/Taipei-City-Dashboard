# 縮短聊天視窗下方邊間距 / Reduce Bottom Side Spacing in ChatBox

## 2026-04-17 15:27

- objective:
  - 依需求縮短「臺北城市儀表板小幫手」下方區塊的頁面邊間距。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 調整下方輸入區 `.input-area` 左右與上下內距，讓底部視覺更貼邊、更精簡。

- change-type:
  - Changed

- technical-details:
  - style:
    - `.input-area` padding 從 `0.625rem 0.75rem` 改為 `0.5rem 0.5rem`。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，僅樣式間距調整。

- impact-risk:
  - 低風險。
  - 可能在極小螢幕上使輸入區更緊湊，但不影響功能。

- regression-test:
  - 驗證聊天輸入區在桌機/手機寬度下未超出容器。
  - 驗證送出按鈕位置與點擊區域正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1449-chatbox-avatar-only-while-responding.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
