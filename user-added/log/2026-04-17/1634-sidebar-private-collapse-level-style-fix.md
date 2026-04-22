# 側欄私人層收合與層級樣式修正 / Sidebar Private Collapse and Hierarchy Style Fix

## 2026-04-17 16:34

- objective:
  - 讓左側導覽列「私人儀表板」也具備第一層整段收合能力（與公共層一致）。
  - 修正第一層文字顏色不一致感受與第二層缺乏縮排的階層辨識問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 在收合狀態中新增 `private` 第一層節點，點擊「私人儀表板」可整段收起第二層與項目。
  - 將私人區塊結構調整為：第一層 `private` 控制第二層（最愛/個人）與第三層項目顯示。
  - 將第一層標題 `h1` 顏色改為 `var(--color-normal-text)`，與階層色彩更一致。
  - 將第二層 `h2` 左內距改為 `24px`，明確呈現第二層縮排。

- change-type:
  - Fixed

- technical-details:
  - `collapsedStates` 新增 `private: false`。
  - 私人第一層 click handler 由 `toggleCollapse(['favorites', 'personal'])` 改為 `toggleCollapse('private')`。
  - 私人第二層區塊以 `v-if="!collapsedStates.private"` 包覆，達成整段收合。
  - `h1` 顏色由 `var(--color-complement-text)` 調整為 `var(--color-normal-text)`。
  - `h2` padding 由 `0 8px 0 8px` 調整為 `0 8px 0 24px`。

- verification:
  - VS Code 診斷檢查：
    - `Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue` -> No errors found
  - 模板邏輯檢查：
    - 私人第一層與公共第一層皆為獨立控制節點。

- performance-impact:
  - 影響極低，僅增加一個布林條件與既有 transition 包覆。
  - 無新增 API 請求與高成本運算。

- impact-risk:
  - 低風險，變更範圍限定在 SideBar 呈現與收合邏輯。
  - 若使用者習慣第一層展開方式，初次操作感受會有輕微改變（功能更符合三層結構）。

- regression-test:
  - 點擊「私人儀表板」：應整段收合/展開「我的最愛、個人儀表板與其項目」。
  - 點擊「公共儀表板」：應整段收合/展開城市與項目（維持先前修正）。
  - 確認第二層標題在展開狀態有明確縮排，收合態不影響置中排列。

- traceability:
  - Related log: user-added/log/2026-04-17/1619-sidebar-public-hierarchy-collapse-font-fix.md

- next-actions:
  - P1: 若要更直觀，可補上第一層/第二層 chevron 並依狀態旋轉。
