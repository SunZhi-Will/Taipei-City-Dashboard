# 延伸指標點擊範圍改為僅文字 / Limit Related Indicator Click Area to Text Only

## 2026-04-22 19:04

- objective:
  - 修正延伸指標連結整行可點擊的行為，改為僅文字區域可點擊。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - secondary links 容器改為 `align-items: flex-start`，避免子元素被拉伸成滿寬。
  - 每個延伸指標按鈕改為 `inline-flex` 並加上 `width: fit-content`，點擊區只包住文字內容。

- change-type:
  - Fixed

- technical-details:
  - 原先 `secondary-links` 使用 column flex 預設 `align-items: stretch`，導致 link 按鈕寬度撐滿整列。
  - 調整後點擊 hit area 與文字寬度一致，符合文字連結（anchor-like）預期。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue，結果為 No errors found。
  - 搜尋確認 `align-items: flex-start` 與 `width: fit-content` 已套用於 secondary links 樣式。

- performance-impact:
  - 無效能影響，僅樣式調整。

- impact-risk:
  - 低風險；僅改動點擊區域，不影響事件處理邏輯。

- regression-test:
  - 滑鼠移到延伸指標時，僅文字附近可觸發點擊。
  - 點擊任一指標仍能正確觸發後續聊天查詢。

- traceability:
  - Related log: user-added/log/2026-04-22/1859-related-indicator-link-style-clickable.md
  - Related log: user-added/log/2026-04-22/1900-remove-secondary-indicator-description-line.md

- next-actions:
  - N/A