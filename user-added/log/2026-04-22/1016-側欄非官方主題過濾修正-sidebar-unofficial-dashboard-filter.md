# 側欄非官方主題過濾修正 / Sidebar Unofficial Dashboard Filter Fix

## 2026-04-22 10:16

- objective:
  - 修正左側導覽列仍顯示非官方主題（使用者回報未移除）的問題，將過濾從 component 層補齊到 dashboard 層。

- files:
  - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
  - Taipei-City-Dashboard-FE/src/store/contentStore.js

- summary:
  - 新增非官方 dashboard 索引清單與判斷函式。
  - 在 setDashboards() 解析 /dashboard/ 回傳資料時，先過濾非官方 dashboard，再進行 personal/public 寫入。
  - 使左側導覽列（SideBar）不再接收到非官方主題項目來源。

- change-type:
  - Fixed

- technical-details:
  - constants：新增 NON_OFFICIAL_DASHBOARD_INDEXES（目前含 aed）與 isOfficialDashboard(dashboard)。
  - contentStore：
    - 匯入 isOfficialDashboard。
    - setDashboards() 內建立 filteredDashboards = dashboardArray.filter(isOfficialDashboard)。
    - personalDashboards 與 city dashboards 均改採 filteredDashboards。
  - 已保留既有 map-layers 排序邏輯（moveMapLayersToEnd）。

- verification:
  - 以 IDE 診斷檢查：
    - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
    - Taipei-City-Dashboard-FE/src/store/contentStore.js
  - 結果：No errors found。

- performance-impact:
  - 低；增加一次 dashboard array 線性過濾，時間複雜度 O(n)，對現有流程影響可忽略。

- impact-risk:
  - 目前 dashboard 層級先以已知非官方索引（aed）過濾；若後續新增其他非官方主題需同步更新清單。
  - 若後端 index 命名改動，需同步調整前端常數。

- regression-test:
  - 建議驗證：
    - 左側導覽列 public/personal 區塊不顯示 aed 主題。
    - 切換城市後側欄仍正常展開/收合。
    - 非 aed 官方主題連結與路由切換正常。

- traceability:
  - user-added/log/2026-04-22/1007-移除非官方資料-remove-unofficial-data.md

- next-actions:
  - 建議後端 /dashboard API 補 official_flag，前端可改為欄位過濾，降低索引清單維護風險。
