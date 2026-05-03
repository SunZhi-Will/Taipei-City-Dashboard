# 側欄公共層級收合與字級修正 / Sidebar Public Hierarchy Collapse and Font Size Fix

## 2026-04-17 16:19

- objective:
  - 修正左側導覽列「公共 > 台北 > 項目」層級互動，讓公共層可收起整段雙北資料。
  - 修正公共層標題字級小於城市層（雙北）造成的視覺層級錯置。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 在側欄收合狀態中新增 public 節點，讓公共層作為真正第一層父節點控制城市與其項目清單顯示。
  - 將公共區塊下方城市清單以條件渲染包裹於 transition，點擊公共標題可整段展開/收合。
  - 調整 h1 標題字級由 11px 改為 var(--font-m)，並調整字重避免比 h2 更小。

- change-type:
  - Fixed

- technical-details:
  - 在 collapsedStates 初始值新增 public: false。
  - 將公共標題 click handler 從 toggleCollapse(contentStore.cityManager.activeCities) 改為 toggleCollapse('public')。
  - 使用 v-if="!collapsedStates.public" 包覆城市層迭代區塊，避免僅收合項目而保留城市列。
  - 樣式層面將 h1 font-size 設為 var(--font-m)，字重改為 600，維持 UI 層級一致性。

- verification:
  - 執行 VS Code 診斷檢查：get_errors 指向 SideBar.vue，結果為 No errors found。
  - 檢查模板邏輯：公共層點擊後會切換 collapsedStates.public，城市與項目區塊同時顯示/隱藏。

- performance-impact:
  - 影響極低，僅新增一個布林條件判斷與既有 transition 包裹。
  - 未引入額外資料請求或重型計算，渲染成本可忽略。

- impact-risk:
  - 可能影響使用者對公共層預設展開狀態的習慣（目前預設仍為展開）。
  - 城市層各自收合狀態在公共層關閉後會保留，屬預期行為；若需每次重置可另行調整。

- regression-test:
  - 驗證桌機展開態：公共可收起/展開，城市與項目同步顯示/隱藏。
  - 驗證城市層：公共展開後，台北/新北可各自收合項目。
  - 驗證側欄最小化：isExpanded false 時 icon 與收合互動無錯誤。

- traceability:
  - Related issue context: 使用者回報「公共無法收起雙北資料且文字比雙北小」。
  - Related log: user-added/log/2026-04-17/1608-sidebar-title-font-size-increase.md

- next-actions:
  - P1: 若要更明確呈現三層關係，可在 h1/h2 增加 chevron 狀態圖示。
  - P2: 補充一個前端互動測試（收合狀態快照）避免回歸。
