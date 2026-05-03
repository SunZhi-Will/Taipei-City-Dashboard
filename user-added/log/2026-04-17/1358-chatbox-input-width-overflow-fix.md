# ChatBox 輸入框超寬修正 / ChatBox Input Width Overflow Fix

## 2026-04-17 13:58

- objective:
  - 修正下方膠囊輸入框超出容器寬度範圍的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在 `.input-shell` 與 `.chat-input` 新增 `box-sizing: border-box;`。
  - 讓 `width: 100%` 計算包含 padding，避免總寬超出父容器。

- change-type:
  - Fixed

- technical-details:
  - Root cause:
    - `.input-shell` 先前使用 `width: 100%` 且含水平 padding，在預設 `content-box` 下會發生實際寬度超出。
  - Fix:
    - `.input-shell { box-sizing: border-box; }`
    - `.chat-input { box-sizing: border-box; }`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，僅盒模型計算方式調整。

- impact-risk:
  - 低風險，僅影響輸入區排版。

- regression-test:
  - 開啟 ChatBox，確認膠囊輸入框不超出右側邊界。
  - 檢查多行輸入時外框寬度仍穩定。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1354-chatbox-compact-layout-and-pill-multiline-input.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
