# 圖表切換列置中還原 / Restore Center Alignment for Chart Switch Row

## 2026-05-03 05:55

- objective:
  - 回應使用者要求，將上方「切換圖表」控制列恢復為置中排列與原本視覺位置。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 將控制列主軸排列從左右分散改回原先置中導向。
  - 將圖表切換按鈕群組恢復為 `margin: 0 auto` 與 `translateX(-15%)` 的置中補償行為。
  - 保留手機斷點下的可換行排版，避免窄螢幕壅塞。

- change-type:
  - Fixed

- technical-details:
  - `.dashboardcomponent-control`
    - `justify-content: space-between` -> `justify-content: flex-start`
    - `flex-wrap: wrap` -> `flex-wrap: nowrap`（桌機）
  - `.dashboardcomponent-control-group`
    - 恢復 `margin: 0 auto`
    - 恢復 `transform: translateX(-15%)`
    - 群組改為 `flex-wrap: nowrap`
  - `@media (max-width: 760px)`
    - 額外保留 `flex-wrap: wrap`，確保手機可正常折行

- verification:
  - VS Code diagnostics：
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found

- performance-impact:
  - 僅 CSS 版面調整，無運算與資料流程變更，效能影響可忽略。

- impact-risk:
  - 置中補償使用固定 `translateX(-15%)`，在極端寬度下可能仍有微小視覺偏移。
  - 已保留手機斷點換行，降低小螢幕重疊風險。

- regression-test:
  - 驗證 map open 模式：圖表切換群組位於中間位置。
  - 驗證切換不同圖表（圓餅圖/動態長條圖）時，按鈕列不跳位。
  - 驗證手機寬度下，選單與按鈕列可正常換行顯示。

- traceability:
  - Related user feedback: 「上面的切換圖表要置中，要恢復原樣」
  - commit: N/A
  - PR: N/A

- next-actions:
  - 若仍覺得中心點略偏，可再把 `translateX(-15%)` 微調為 `-12%` 或 `-10%` 以貼合你目前版型。
