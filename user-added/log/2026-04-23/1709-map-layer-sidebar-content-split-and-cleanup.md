# 地圖側欄內容拆分與重複 SFC 清理 / Split Map Sidebar Content and Clean Duplicate SFC

## 2026-04-23 17:09

- objective:
  - 修復 MapLayerSidebarContent.vue 因重複 script/template/style 區塊造成的 Vue SFC 編譯錯誤。
  - 將重複的 dashboard list 模板拆成子元件，降低主檔再次被大段拼接污染的風險。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue

- summary:
  - 新增 MapDashboardListSection，承接 dashboard row 與 component checkbox list 的重複模板。
  - 重建 MapLayerSidebarContent，改為只保留狀態、資料取得、事件處理與分組組裝。
  - 移除主檔內重複 template，將私人最愛、個人儀表板、公共儀表板統一走子元件渲染。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 子元件 props 包含 dashboards、scope、city、expandedDashboardMap、componentToggles 與 key/helper functions。
  - 子元件 emits：dashboard-click、component-toggle，讓主檔保留資料流控制權。
  - 主檔樣式對子元件採用 :deep(...) 套用，避免樣式因 scoped 邊界失效。

- verification:
  - 使用 VS Code diagnostics (`get_errors`) 檢查：
    - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
    - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue
  - 結果：兩個檔案皆 No errors found。

- performance-impact:
  - 無顯著執行期效能影響。
  - 模板重複減少後，維護成本與再次發生大檔衝突的風險下降。

- impact-risk:
  - 低風險：變更集中於 map sidebar 內容元件。
  - 若未來子元件 props/emit 命名被改動，需同步更新父元件綁定。

- regression-test:
  - 進入 mapview，確認側欄可正常顯示。
  - 點私人最愛、個人儀表板、公共儀表板 row 仍可切換並展開。
  - component checkbox 勾選/取消仍可同步地圖圖層。

- traceability:
  - Related logs:
  - user-added/log/2026-04-23/1709-map-layer-sidebar-sfc-duplicate-cleanup.md

- next-actions:
  - P1: 若同類重複拼接仍持續發生，可補一個 SFC 結構檢查腳本或 pre-commit guard。