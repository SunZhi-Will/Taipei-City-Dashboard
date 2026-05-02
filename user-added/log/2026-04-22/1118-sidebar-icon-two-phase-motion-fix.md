# 側欄圖示兩段位移修正 / Sidebar Icon Two-Phase Motion Fix

## 2026-04-22 11:18

- objective:
  - 修正側欄收合時 icon 先往右再往左的反向位移，讓動畫路徑自然且單向。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue
  - Taipei-City-Dashboard-FE/src/components/utilities/miscellaneous/SideBarTab.vue
- summary:
  - 將收合行為改為兩段式：先收文字，再延遲 icon 移動到收合中心。
  - 避免使用立即 `justify-content: center` 導致 icon 受文字寬度影響產生反向位移。
- change-type:
  - Fixed
- technical-details:
  - `SideBar.vue`:
  - `h1/h2` transition 增加 padding/margin 過渡。
  - `sidebar-icon` 新增 `margin-left` 過渡與 collapsed 狀態 delay。
  - collapsed 狀態改為 `justify-content: flex-start`，並以 `margin-left: calc((3.5rem - 16px)/2)` 將 icon 對齊中心軌道。
  - `:deep(.sidebartab)` 在 collapsed 狀態也改為 `flex-start` 與零外距，避免布局二次計算造成反向位移。
  - `SideBarTab.vue`:
  - `sidebartab-icon` 改為 `margin-left + margin-right` 雙向過渡。
  - `sidebartab-collapsed` 改為 `flex-start`，再用 `margin-left: calc((3.5rem - 17px)/2)` 延遲移動 icon 到中心。
- verification:
  - `get_errors`:
  - SideBar.vue: No errors found
  - SideBarTab.vue: No errors found
  - 建議手動檢查：
  - 展開→收合時 icon 不應再出現右後左反向位移。
  - 收合完成時 icon 應落在視覺中心。
- performance-impact:
  - 純 CSS transition 與 margin 計算，性能影響可忽略。
- impact-risk:
  - 低風險，僅收合動畫行為調整。
- regression-test:
  - 驗證 sidebar section header 與 sidebartab 在 dashboard/mapview 的收合軌跡一致。
  - 驗證 active/hover 樣式在 collapsed/expanded 皆正常。
- traceability:
  - log: user-added/log/2026-04-22/1118-sidebar-icon-two-phase-motion-fix.md
  - ticket/PR/commit: N/A
- next-actions:
  - N/A
