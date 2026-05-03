# Dashboard 下方間距明確化 / Clarify Dashboard Bottom Spacing

## 2026-04-22 14:07

- objective:
  - 讓 dashboard 容器的 margin 明確包含下方間距，避免視覺上誤解或後續維護混淆。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 將 `.dashboard` 的 `margin` 由雙值寫法改為四值寫法。
  - 新寫法明確指定上/右/下/左皆為 `var(--font-m)`，其中下方間距明確保留。

- change-type:
  - Changed

- technical-details:
  - 原始：`margin: var(--font-m) var(--font-m);`
  - 調整後：`margin: var(--font-m) var(--font-m) var(--font-m) var(--font-m);`
  - 視覺結果與既有設計一致，但可讀性與維護可理解性更高。

- verification:
  - 檔案檢查：確認 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` 內 `.dashboard` 樣式已更新為四值 margin。
  - 視覺檢查建議：在 dashboard 頁面確認底部卡片區塊與容器邊界存在 `var(--font-m)` 間距。

- performance-impact:
  - 無效能影響，僅樣式宣告可讀性調整。

- impact-risk:
  - 低風險，未變更 layout 計算邏輯與 DOM 結構。
  - 如專案有 style lint 規範偏好簡寫，需確認是否允許四值顯式寫法。

- regression-test:
  - Dashboard 頁面：確認卡片列表底部保有間距。
  - 響應式斷點：720px、1296px、1800px、2200px 檢查 grid 排版與邊界留白。

- traceability:
  - Related log: user-added/log/2026-04-22/1344-app-ui-scroll-enhancement.md

- next-actions:
  - N/A
