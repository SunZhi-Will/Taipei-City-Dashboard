# 發送按鈕雙圈視覺修正 / Send Button Double-Circle Visual Fix

## 2026-04-17 14:34

- objective:
  - 移除發送按鈕「外圈包內圈」的視覺效果，改為單一圓形按鈕。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 保留外層 `.send-btn` 圓形按鈕樣式。
  - 隱藏 `SendIcon` 內建的 `circle` 元素，避免形成內圈。
  - 將 `SendIcon` 的 `path` 強制為白色，確保深色按鈕上的對比可讀性。

- change-type:
  - Fixed

- technical-details:
  - selector updates:
    - `:deep(svg circle) { display: none; }`
    - `:deep(svg path) { fill: #fff; }`
  - 既有按鈕尺寸與定位（30x30、右下內嵌）維持不變。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，純視覺呈現調整。

- impact-risk:
  - 低風險，僅影響送出圖示的內部樣式。

- regression-test:
  - 開啟聊天視窗，確認送出按鈕只顯示單一圓形。
  - 驗證 disabled/hover 狀態仍正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1354-chatbox-compact-layout-and-pill-multiline-input.md
    - user-added/log/2026-04-17/1400-chatbox-input-rounded-rectangle.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
