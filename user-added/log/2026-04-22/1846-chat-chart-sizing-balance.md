# 調整聊天圖表尺寸比例 / Adjust Chat Chart Size Balance

## 2026-04-22 18:46

- objective:
  - 修正聊天中圖表外框過高、但內部圖表視覺上偏小的比例失衡問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 將聊天主圖表的 DashboardComponent 由 `focus` 模式改為 `large` 模式，避免套用接近整個視窗高度的布局。
  - 關閉聊天圖表卡的 footer，釋出更多空間給實際圖表區。
  - 微調聊天圖表外框 padding，讓卡片視覺更緊湊。

- change-type:
  - Fixed

- technical-details:
  - `focus` 模式在 DashboardComponent 中會使用接近全視窗高度的尺寸，適合單頁詳情，不適合嵌在聊天訊息內。
  - `large` 模式保留完整圖表渲染，但高度較穩定，和聊天卡片容器比例更一致。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue，結果為 No errors found。
  - 以搜尋確認聊天圖表目前使用 `mode="large"` 且 `:footer="false"`。

- performance-impact:
  - 無額外 API 或運算負擔，僅為前端顯示尺寸調整。

- impact-risk:
  - 若某些特殊圖表高度原本依賴 `focus` 模式的超高容器，改用 `large` 後可能需要再微調個別圖表內部 spacing。

- regression-test:
  - 測試聊天主圖表在桌機寬度下的比例，確認容器不再過高。
  - 測試不同類型圖表在聊天卡中的可讀性，確認標題、圖形與圖例不互相擠壓。

- traceability:
  - Related log: user-added/log/2026-04-22/1827-chat-ai-summary-and-chart-rendering.md
  - Related log: user-added/log/2026-04-22/1835-chat-chart-data-hydration-fix.md

- next-actions:
  - 若仍有特定圖表看起來偏小，下一步改針對該 chart component 本身做內部高度與字級調整。