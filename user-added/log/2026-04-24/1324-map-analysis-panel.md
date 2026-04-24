# 地圖分析面板回補實作 / Map Analysis Panel Reintroduction

## 2026-04-24 13:24

- objective:
  - 在不破壞既有地圖頁 UIUX 的前提下，回補可由圖表觸發地圖篩選的互動分析能力。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue
  - Taipei-City-Dashboard-FE/src/views/MapView.vue
- summary:
  - 新增地圖分析面板，讓使用者可從左側圖層清單點擊「分析」開啟互動圖表。
  - 保留現有左欄儀表板/圖層勾選流程，不改動主要資訊架構與版面密度。
  - 將圖表篩選事件接回 mapStore（byParam/byLayer/clear），恢復地圖交叉比對體驗。
- change-type:
  - Changed
- technical-details:
  - 新增 `MapAnalysisPanel.vue`，內嵌 `DashboardComponent`（map mode）並轉接 `filter-by-param`、`filter-by-layer`、`clear-*`、`fly` 到 `mapStore`。
  - 在 `MapDashboardListSection.vue` 每個 component item 增加「分析」按鈕，透過 `component-analyze` 事件向上傳遞選取元件。
  - 在 `MapLayerSidebarContent.vue`、`useMapLayerSidebarContent.js`、`MapLayerSidebar.vue` 串接 `open-analysis` 事件鏈。
  - 在 `MapView.vue` 增加 `selectedAnalysisComponent` 狀態並渲染分析面板，支援開關閉。
- verification:
  - 使用 VS Code diagnostics 檢查以下檔案，結果均為 `No errors found`：
    - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
    - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue
    - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
    - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
    - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue
    - Taipei-City-Dashboard-FE/src/views/MapView.vue
- performance-impact:
  - 面板採條件渲染，僅在使用者點擊「分析」時載入圖表元件，可降低常態渲染負擔。
  - 新增事件處理為 O(1) UI 狀態更新，對既有地圖渲染主流程影響低。
- impact-risk:
  - 風險：面板開啟後高度較大，可能在部分小尺寸桌面遮蔽地圖資訊。
  - 緩解：保留關閉按鈕並維持浮層型態，後續可再加入可拖曳/可縮放。
- regression-test:
  - 驗證地圖頁原有操作：左欄展開/收合、儀表板切換、圖層勾選、圖層顯示切換。
  - 驗證新流程：點擊「分析」開啟面板、圖表點擊後地圖篩選生效、關閉面板時清除篩選。
  - 驗證 mobile/desktop 響應：desktop 顯示分析面板，mobile 不顯示該浮層（維持既有行為）。
- traceability:
  - N/A
- next-actions:
  - 加入「目前篩選條件」chips 與一鍵清除按鈕，提升篩選可見性與可回復性（P1）。
