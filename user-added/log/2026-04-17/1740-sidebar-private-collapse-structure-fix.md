# 私人側欄二層收合結構修復 / Private Sidebar Second-Level Collapse Structure Fix

## 2026-04-17 17:40

- objective:
  - 修復左側導覽列中「私人儀表板」第一層收合無法隱藏第二層標題（我的最愛、個人儀表板）的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 新增 `collapsedStates.private` 並將私人第一層按鈕改為 `toggleCollapse('private')`。
  - 以 `v-if="!collapsedStates.private"` 包覆整段私人第二層內容，確保標題與子項目同時收合。
  - 同步修正側欄樣式一致性：`h1` 顏色改為 `var(--color-normal-text)`、`h2` 左縮排改為 `0 8px 0 24px`。

- change-type:
  - Fixed

- technical-details:
  - 原先僅切換 `favorites/personal`，導致只隱藏子清單，不會隱藏第二層 `h2` 標題。
  - 透過新增 private 層級狀態，將私人區塊調整為三層控制：
    - 第一層：private（整段收合）
    - 第二層：favorites / personal（各自細項收合）
    - 第三層：SideBarTab 清單項目
  - 為避免編碼污染造成字元異常，私人與公共標題改用 Unicode escape 字串（例如 `\u79c1\u4eba\u5100\u8868\u677f`）。

- verification:
  - 編譯診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue`，結果 `No errors found`。
  - 關鍵字驗證（grep）：
    - `toggleCollapse('private')`
    - `v-if="!collapsedStates.private"`
    - `padding: 0 8px 0 24px;`
    - `color: var(--color-normal-text);`
  - 結果：以上關鍵字均存在於目標檔案。

- performance-impact:
  - 變更為條件渲染與狀態切換，對渲染效能影響可忽略。
  - 預期可減少不必要的 DOM 顯示，並提升導覽可讀性。

- impact-risk:
  - 若其他邏輯依賴私人區塊常駐顯示，可能出現可見性變化（低風險）。
  - 已保留 favorites/personal 原收合邏輯，降低既有互動回歸風險。

- regression-test:
  - 點擊「私人儀表板」：確認「我的最愛」「個人儀表板」與其子項目一起隱藏/展開。
  - 點擊「我的最愛」「個人儀表板」：確認各自第三層清單可獨立收合。
  - 驗證「公共儀表板」收合行為未受影響。
  - 驗證手機與桌機寬度下側欄縮排與字色一致。

- traceability:
  - Related conversation: user report with sidebar DOM snapshot (2026-04-17)

- next-actions:
  - 建議在瀏覽器實測一次：私人第一層收合時，不應再看到第二層標題。
