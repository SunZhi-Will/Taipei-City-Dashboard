# 側欄收合遮罩修正 / Sidebar Masked Collapse Fix

## 2026-04-22 10:59

- objective:
  - 修正側欄收合時文字直接消失與 icon 橫向位移問題，改為遮罩式收合體驗。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue
  - Taipei-City-Dashboard-FE/src/components/utilities/miscellaneous/SideBarTab.vue
- summary:
  - 將文字收合改為 `max-width + clip-path` 遮罩裁切，不再以 visibility 直接隱藏。
  - 收合狀態移除置中對齊，改為固定左對齊，避免 icon 在動畫期間偏移。
  - 移除「最愛/個人」短字替代節點，統一用同一份文字做遮罩式收合。
- change-type:
  - Fixed
- technical-details:
  - `SideBar.vue`:
  - `sidebar-label` 新增 `clip-path` 與較平滑 transition，`is-hidden` 狀態改為裁切到右側。
  - `sidebar-collapse h1/h2` 由 `justify-content: center` 改為 `flex-start`。
  - `:deep(.sidebartab)` 在收合時保持 `flex-start`，並維持固定 padding 軌道。
  - `favorites/personal` 區塊移除 short label 分支，避免雙文字切換跳動。
  - `SideBarTab.vue`:
  - `sidebartab-label` 改為遮罩式收合，移除收合態置中與 icon margin 切換。
- verification:
  - `get_errors`:
  - SideBar.vue: No errors found
  - SideBarTab.vue: No errors found
  - 手動檢查建議：
  - 展開→收合時 icon 應固定，不可左右跳動。
  - 收合過程中文字應呈現被裁切感，不應突然消失。
- performance-impact:
  - 僅 CSS transition 調整，無額外執行緒與資料處理開銷。
- impact-risk:
  - 低風險，僅 UI 收合與排版樣式調整。
- regression-test:
  - 驗證私人/公共區塊與 tab item 在展開/收合狀態下的可點擊範圍一致。
  - 驗證 dashboard 與 mapview 兩頁的側欄動畫一致。
- traceability:
  - log: user-added/log/2026-04-22/1059-sidebar-mask-collapse-fix.md
  - ticket/PR/commit: N/A
- next-actions:
  - N/A
