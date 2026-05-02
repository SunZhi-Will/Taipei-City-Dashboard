# 發送 Icon 放大 / Increase Send Icon Size

## 2026-04-22 10:28

- objective:
  - 修正聊天輸入欄發送 icon 過小問題，提高可見性。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將 send button 內 svg 尺寸由 16px 提升為 20px。

- change-type:
  - Changed

- technical-details:
  - `.send-btn :deep(svg)`
    - `width: 16px -> 20px`
    - `height: 16px -> 20px`

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，僅 UI 尺寸調整。

- impact-risk:
  - 低風險；僅 icon 視覺尺寸變更。

- regression-test:
  - 檢查 desktop/mobile 下送出鍵 icon 顯示與置中。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1025-chat-send-center-and-launcher-clip-fix.md

- next-actions:
  - N/A
