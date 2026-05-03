# 移除延伸指標第二行描述 / Remove Secondary Description Line for Related Indicators

## 2026-04-22 19:00

- objective:
  - 依使用者需求移除延伸指標連結下方的第二行描述文字。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 移除延伸指標連結中的描述文字節點（例如「可作為進一步延伸參考。」）。
  - 刪除對應 description 樣式，僅保留可點擊的單行連結名稱。

- change-type:
  - Changed

- technical-details:
  - secondary 區塊每個 link item 現僅渲染 `secondary-link-name`。
  - `secondary-link-description` 樣式已移除，避免殘留無用 CSS。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue，結果為 No errors found。
  - 搜尋確認檔案內已無 `secondary-link-description` 節點與樣式定義。

- performance-impact:
  - 無效能影響，僅 UI 文字節點減少。

- impact-risk:
  - 無功能風險，點擊行為與事件流保持不變。

- regression-test:
  - 檢查延伸指標區塊是否只剩單行可點擊文字。
  - 點擊任一指標，確認仍可觸發後續查詢。

- traceability:
  - Related log: user-added/log/2026-04-22/1859-related-indicator-link-style-clickable.md

- next-actions:
  - N/A