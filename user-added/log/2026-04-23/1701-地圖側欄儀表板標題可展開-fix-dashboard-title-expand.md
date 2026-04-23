# 地圖側欄儀表板標題可展開修正 / Fix Dashboard Title Expand in Map Sidebar

## 2026-04-23 17:01

- objective:
  - 解決地圖側欄中儀表板列僅能點右側箭頭展開，點名稱無法展開造成互動不一致的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 新增 `handleDashboardTitleClick`，將左側儀表板名稱按鈕改為「切換儀表板 + 若尚未展開則自動展開」。
  - 保留右側箭頭按鈕既有「展開/收合切換」邏輯，避免改變既有使用者習慣。

- change-type:
  - Fixed

- technical-details:
  - 在 `switchDashboard` 與 `toggleDashboardExpand` 之間新增整合入口 `handleDashboardTitleClick(scope, dashboard, city)`。
  - 以 `buildDashboardKey` 判斷目前 dashboard 是否已展開，僅在未展開時呼叫 `toggleDashboardExpand`。
  - 更新三處名稱按鈕 click 綁定：私人最愛、個人儀表板、公共儀表板。

- verification:
  - 使用 VS Code 診斷檢查：`get_errors` 檢查 `MapLayerSidebarContent.vue`，結果為 No errors found。
  - 靜態檢查事件綁定：三個 dashboard row 的左側按鈕皆改綁 `handleDashboardTitleClick(...)`。

- performance-impact:
  - 影響極小。僅在名稱按鈕點擊時增加一次展開狀態判斷與必要時的既有資料載入流程。
  - 無新增輪詢、watcher 或大型計算。

- impact-risk:
  - 低風險。右側箭頭維持原邏輯；左側新增行為只在未展開時觸發展開，不會強制收合。
  - 若使用者原本只想切換不展開，互動會改為同步展開，屬預期調整。

- regression-test:
  - 點擊私人最愛名稱應切換並展開 component list。
  - 點擊個人儀表板名稱應切換並展開 component list。
  - 點擊公共儀表板名稱應切換並展開 component list。
  - 點擊右側箭頭仍可正常展開與收合。

- traceability:
  - Related log: user-added/log/2026-04-23/1700-map-city-select-to-toggle.md

- next-actions:
  - P1: 若要更一致的 UX，可評估將整列 row 設為單一可點擊區，並為箭頭使用 `stopPropagation`。