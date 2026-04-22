# 公告白字回滲修正 / Sticky Notice White Text Regression Fix

## 2026-04-22 10:32

- objective:
  - 修正置頂公告卡片再次出現白色文字問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在公告卡片內針對標題與內文的文字節點（span/p）顯式指定深色，避免全域 `*` 字色規則回滲。

- change-type:
  - Fixed

- technical-details:
  - `.sticky-header span { color: #27272a; }`
  - `.sticky-body span, .sticky-body p { color: #18181b; }`
  - 透過更具體 selector 對抗全域通配符字色。

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，純樣式修正。

- impact-risk:
  - 低風險；僅影響公告卡片文字顏色。

- regression-test:
  - 展開/收合公告時標題與內文保持深色可讀。
  - 不影響其他聊天訊息文字顏色。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1031-chat-sticky-card-restored.md

- next-actions:
  - N/A
