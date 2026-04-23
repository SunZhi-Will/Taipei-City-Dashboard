# 地圖側欄修復與邏輯拆分 / Map Sidebar Fix and Logic Split

## 2026-04-23 17:43

- objective:
  - 修復 `MapLayerSidebarContent.vue` 因檔案內容破損造成的 Vue template 編譯錯誤（Element is missing end tag）。
  - 將側欄邏輯從元件中拆分，降低檔案複雜度並提升維護性。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js

- summary:
  - 重新建立乾淨版 `MapLayerSidebarContent.vue`，移除重複拼接與破碎片段，恢復單一合法的 SFC 結構（script/template/style）。
  - 新增 composable `useMapLayerSidebarContent.js`，將 dashboard 展開、組件快取、地圖同步、城市切換等邏輯抽離。
  - 保留既有 `MapDashboardListSection.vue` 組件介面，改以事件物件傳遞維持行為一致。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `MapLayerSidebarContent.vue` 改為薄視圖層：僅負責模板結構、樣式與綁定 composable 回傳狀態/方法。
  - `useMapLayerSidebarContent.js` 實作：
    - `buildDashboardKey`、`componentKey` 鍵值生成。
    - `ensureDashboardComponents` API 載入與快取控制。
    - `handleDashboardRowClick` 與 `toggleDashboardExpand` 展開流程。
    - `handleComponentSyncToggle` 對 `mapStore` 進行 add/clear/visibility 操作。
    - 監聽 `publicCityOptions`，確保 `selectedPublicCity` 始終有效。
  - 透過 `:deep(...)` 保留子組件 class 的 scoped style 覆蓋效果。

- verification:
  - 使用 VS Code diagnostics 檢查以下檔案皆無錯誤：
    - `Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue`
    - `Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js`
    - `Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue`
  - 驗證方式：`get_errors` 工具（語法與語意檢查）。

- performance-impact:
  - 主要為結構重整，執行路徑與資料流維持一致。
  - composable 抽離可降低 SFC 解析與維護成本，對執行效能影響可忽略。

- impact-risk:
  - 風險：`MapDashboardListSection.vue` 事件 payload 若未維持原契約，可能導致展開/同步行為異常。
  - 緩解：保持 `dashboard-click` 與 `component-toggle` payload 結構一致，並以診斷檢查確認無新增錯誤。

- regression-test:
  - 建議回歸：
    - 私人儀表板（我的最愛、個人儀表板）展開/收合。
    - 公共儀表板 city toggle（taipei/metrotaipei）切換。
    - 組件 checkbox 勾選後圖層顯示、取消後清除與關閉可見性。
    - 無 `map_config` 組件勾選時通知提示行為。

- traceability:
  - Related log: user-added/log/2026-04-23/1743-map-sidebar-content-refactor-fix.md
  - Ticket/PR/commit: N/A

- next-actions:
  - P1: 在實際執行環境手動驗證地圖圖層同步與 dashboard 切換流程。
  - P2: 如需進一步拆分，可將私人/公共區塊再拆為獨立 Vue 子元件。
