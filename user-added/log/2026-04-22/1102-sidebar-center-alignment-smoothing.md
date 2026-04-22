# 側欄置中與位移平滑修正 / Sidebar Center Alignment Smoothing

## 2026-04-22 11:02

- objective:
  - 修正收合後 icon 未置中與收合過程瞬間位移問題，改善視覺穩定性。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue
  - Taipei-City-Dashboard-FE/src/components/utilities/miscellaneous/SideBarTab.vue
- summary:
  - 收合態恢復置中對齊，並為 icon margin 與 row padding 加入 transition。
  - 保留遮罩式文字收合，同時讓 icon 在收合過程更平滑，不再突跳。
- change-type:
  - Fixed
- technical-details:
  - `SideBar.vue`:
  - `sidebar-collapse h1/h2` 改回 `justify-content: center`。
  - `sidebar-icon` 新增 `margin-right` transition。
  - `sidebar-chevron` 新增 transition，避免收合瞬間切換感。
  - `:deep(.sidebartab)` 收合態改回 `justify-content: center`。
  - `SideBarTab.vue`:
  - `sidebartab` 新增 `padding` transition。
  - `sidebartab-icon` 新增 `margin-right` transition。
  - `sidebartab-collapsed` 明確設為 `justify-content: center` 並將 icon 右邊距漸進收斂。
- verification:
  - `get_errors`:
  - SideBar.vue: No errors found
  - SideBarTab.vue: No errors found
  - 建議手動檢查：
  - 展開→收合時 icon 終態置中。
  - 收合過程 icon 不應有瞬間左跳。
- performance-impact:
  - 僅 CSS transition 微調，效能影響可忽略。
- impact-risk:
  - 低風險，僅側欄樣式調整。
- regression-test:
  - 驗證 dashboard/mapview 頁面收合動畫一致。
  - 驗證 sidebartab active 樣式在收合態仍正確。
- traceability:
  - log: user-added/log/2026-04-22/1102-sidebar-center-alignment-smoothing.md
  - ticket/PR/commit: N/A
- next-actions:
  - N/A
