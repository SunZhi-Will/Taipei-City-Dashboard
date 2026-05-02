# 地圖頁組件城市下拉整合 / Map Per-Component City Selector Integration

## 2026-05-03 05:06

- objective:
  - 讓 mapview sidebar 展開 dashboard 後，每個 component 都可直接切換「臺北 / 雙北」城市版本。
  - 重用既有 DashboardComponent 的 map mode，避免在地圖頁重寫重複 UI 與互動邏輯。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - user-added/log/2026-05-03/0506-map-per-component-city-selector.md

- summary:
  - 將 map sidebar 原本的 checkbox 文字列改為嵌入 `DashboardComponent` 的 `mode="map"` 版本。
  - 補上 per-component `change-city` 事件，讓單一組件可在不切換整個 dashboard city 的情況下切換資料來源。
  - 若該組件已經開啟地圖圖層，切換城市時會同步關閉舊 map config、掛上新城市 map config，並更新 analysis panel 指向的新組件。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `MapDashboardListSection.vue`
    - 新增 `DashboardComponent` 與 `contentStore` 引入。
    - 用 `DashboardComponent` 取代原本 `<label>` + checkbox 的列表列。
    - 透過 `contentStore.cityManager.getSelectList(component.city)` 與 `getTagList(component.city)` 提供城市選單與標籤。
    - 新增 `component-city-change` emit，將單一組件的城市切換往父層傳遞。
    - 補上 sidebar 內部 `:deep(.dashboardcomponent.mapclosed/.mapopen)` 寬度限制，避免元件寬度撐破列表。
  - `MapLayerSidebarContent.vue`
    - 將 `component-city-change` 接到 composable 處理函式。
  - `useMapLayerSidebarContent.js`
    - 新增 `componentCitySelections` 狀態，以 `dashboardIndex + city scope + componentIndex` 管理每個組件當前選到的城市版本。
    - `getDashboardComponents()` 由固定回傳 dashboard 預設城市資料，改為可依 per-component 選擇返回對應 city variant。
    - 新增 `handleComponentCityChange()`，在已開啟圖層時同步更新 map layer 與 analysis panel。

- verification:
  - VS Code 診斷：`get_errors` 檢查以下檔案，結果皆為 `No errors found`
    - `Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue`
    - `Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue`
    - `Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js`
  - 頁面驗證：需再於瀏覽器中確認 mapview 的實際下拉互動流程。

- performance-impact:
  - 新增的 per-component 選擇狀態僅為小型記憶體映射，效能影響低。
  - 已開啟圖層時切換城市會多一次舊圖層清理與新圖層掛載，但屬使用者主動操作，成本可接受。

- impact-risk:
  - 若某 dashboard 快取資料缺少指定城市 variant，該組件會保留原版本，不會強制切換。
  - 若其他模組直接依賴 `componentToggles` 舊 key，不同城市版本切換後會改用新 key；目前此 composable 內部流程已同步處理。

- regression-test:
  - 驗證 mapview 公共儀表板展開後，每個 component 都可見城市下拉。
  - 驗證切換「臺北 / 雙北」後，chart 內容會切換到對應城市版本。
  - 驗證組件 toggle 開啟狀態下切換城市，地圖圖層與 analysis panel 會切到新城市版本。
  - 驗證無 map config 的組件仍顯示 `無地圖` 且分析按鈕維持 disabled。

- traceability:
  - Related request: 使用者要求「地圖頁加 per-component city 下拉選單」。

- next-actions:
  - 建議在本機瀏覽器補跑一次完整互動驗證，確認 food safety 的 7 個 component 都能正常切換城市。