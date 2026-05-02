# Dashboard 底部間距可視修正 / Dashboard Bottom Spacing Visibility Fix

## 2026-04-22 14:09

- objective:
  - 修正 dashboard 實際僅有左上右間距、底部間距不可見的問題。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 將 `.dashboard` 的 margin 由四邊改為上/右/左保留、底部設為 0。
  - 新增 `padding-bottom: var(--font-m)`，確保在可滾動容器中底部留白實際可見。
  - 保持 `overflow-y: auto`，避免始終顯示滾動條。

- change-type:
  - Fixed

- technical-details:
  - 原始：`margin: var(--font-m) var(--font-m) var(--font-m) var(--font-m);`
  - 調整後：`margin: var(--font-m) var(--font-m) 0 var(--font-m);`
  - 新增：`padding-bottom: var(--font-m);`
  - 原因：在滾動情境中，容器外部底部 margin 容易在視覺上被裁切；改為內部 padding 可穩定呈現底部空間。

- verification:
  - 檔案檢查：確認 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` 中 `.dashboard` 已包含 `padding-bottom`。
  - 視覺檢查：在 dashboard 頁面向下滾動到底，確認最後一列卡片下方仍保留 `var(--font-m)` 空間。

- performance-impact:
  - 無顯著效能影響，僅 CSS 佈局留白策略調整。

- impact-risk:
  - 低風險，僅影響 dashboard 容器底部留白呈現。
  - 若有依賴容器總高度的截圖或視覺比對測試，需同步更新 baseline。

- regression-test:
  - Dashboard 卡片頁面：滾到底確認底部留白。
  - 響應式斷點：720px、1296px、1800px、2200px 檢查留白一致性。

- traceability:
  - Related log: user-added/log/2026-04-22/1407-dashboard-margin-bottom-spacing.md

- next-actions:
  - N/A
