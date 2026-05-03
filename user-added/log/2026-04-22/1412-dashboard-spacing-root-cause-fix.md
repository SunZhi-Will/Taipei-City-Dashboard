# Dashboard 間距根因修正 / Dashboard Spacing Root Cause Fix

## 2026-04-22 14:12

- objective:
  - 深度分析 `.dashboard` 底部間距不顯示原因，修正為四邊間距一致可見。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 根因確認：`.dashboard` 同時承擔 grid + scroll container，導致底部間距在滾動視窗中視覺上被吃掉。
  - 調整策略：將滾動責任統一回 `app-content-body`，`.dashboard` 回復純內容容器。
  - `.dashboard` 使用四值 margin 明確保留四邊間距；`app-content-body` 增加底部 padding 提供穩定可視緩衝。

- change-type:
  - Fixed

- technical-details:
  - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`
    - `.dashboard`：
      - 由 `margin: var(--font-m) var(--font-m) 0 var(--font-m);` 改為 `margin: var(--font-m) var(--font-m) var(--font-m) var(--font-m);`
      - 移除 `padding-bottom: var(--font-m);`
      - 移除 `overflow-y: auto;`
  - `Taipei-City-Dashboard-FE/src/App.vue`
    - `.app-content-body`：
      - 由 `padding-bottom: 0;` 改為 `padding-bottom: var(--font-m);`
      - 保留 `overflow-y: auto;`
  - 目的：避免「內層可滾動容器」造成底部外距不可見，並保留父層統一捲動機制。

- verification:
  - 檔案檢查：
    - 確認 `.dashboard` 已無 `overflow-y`，且 margin 為四值。
    - 確認 `.app-content-body` 已有 `padding-bottom: var(--font-m)`。
  - 視覺檢查：
    - dashboard 頁面滾到底部，最後一列卡片與視窗底部應有約 18px 留白。
    - 檢查上/右/左/下留白一致性。

- performance-impact:
  - 無顯著效能影響；僅調整 scroll container 層級與間距策略。

- impact-risk:
  - 低風險，但可能影響其他視圖在 `app-content-body` 內的底部留白呈現。
  - 若有截圖比對測試，需更新 baseline。

- regression-test:
  - dashboard: 卡片列表滾到底視覺間距。
  - mapview/component/admin: 確認底部留白不影響互動。
  - 響應式斷點：720/1296/1800/2200。

- traceability:
  - Related logs:
    - user-added/log/2026-04-22/1407-dashboard-margin-bottom-spacing.md
    - user-added/log/2026-04-22/1409-dashboard-bottom-spacing-visible-fix.md

- next-actions:
  - 若希望 dashboard 與其他視圖留白策略分離，可改為只在 dashboard route 條件套用底部 padding。
