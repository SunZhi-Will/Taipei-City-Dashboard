# 勾選即開分析與面板去外層包裝 / Auto Open Analysis on Toggle and Unwrapped Panel

## 2026-04-24 14:03

- objective:
  - 讓地圖圖層 checkbox 勾選後，左下角分析自動開啟。
  - 移除分析面板內圖表額外外層包裝造成的視覺層級感，維持更貼近原圖表樣貌。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue
  - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - user-added/log/2026-04-24/1403-map-analysis-auto-open-and-unwrapped-panel.md

- summary:
  - 在 map sidebar 的 checkbox toggle 流程中新增自動開啟分析事件，勾選時直接開啟左下分析面板。
  - 取消勾選時新增 close-analysis 事件，若目前顯示的是同一個 component，則自動關閉分析面板。
  - 重構分析面板模板，移除 header/body 雙層包裝，改為單層容器 + 浮層標籤與關閉按鈕。
  - 為 DashboardComponent 新增 `noOuterContainer`，允許在分析面板使用 `display: contents` 取消外層容器布局影響。

- change-type:
  - Fixed

- technical-details:
  - `useMapLayerSidebarContent.js`:
    - `handleComponentSyncToggle` 在 `checked=true` 時 `emit("open-analysis", payload)`。
    - `checked=false` 時 `emit("close-analysis", { component })`。
  - `MapLayerSidebarContent.vue` / `MapLayerSidebar.vue`:
    - 補齊 `close-analysis` emits 與事件轉發。
  - `MapView.vue`:
    - 新增 `handleCloseAnalysisByToggle`，僅關閉目前顯示且同 id 的分析組件。
  - `DashboardComponent.vue`:
    - 新增 prop `noOuterContainer`，並在 `.dashboardcomponent-fullscreen-container--none` 套用 `display: contents`。
  - `MapAnalysisPanel.vue`:
    - 使用 `:no-outer-container="true"`。
    - 精簡模板層次，改為單層面板 + overlay controls。

- verification:
  - VS Code diagnostics (`get_errors`)：
    - `useMapLayerSidebarContent.js` -> No errors found
    - `MapLayerSidebarContent.vue` -> No errors found
    - `MapLayerSidebar.vue` -> No errors found
    - `MapView.vue` -> No errors found
    - `MapAnalysisPanel.vue` -> No errors found
    - `DashboardComponent.vue` -> No errors found

- performance-impact:
  - 影響極低，僅新增少量事件發射與條件分支。
  - `display: contents` 不增加渲染成本，反而減少一層可見容器樣式負擔。

- impact-risk:
  - 中低風險：
  - `display: contents` 在少數舊瀏覽器對可及性樹行為可能有差異，但現行專案目標瀏覽器影響有限。
  - 勾選即開分析改變既有互動，若使用者只想開圖層不想開分析，需評估是否加入偏好開關。

- regression-test:
  - 勾選有 map_config 的 component，左下分析面板應立即出現。
  - 取消勾選目前分析中的 component，面板應關閉。
  - 點擊「分析」按鈕仍可正常開啟分析。
  - 分析面板內圖表仍可觸發 `filter-by-param` / `filter-by-layer`。
  - 手動關閉分析時，地圖篩選可正常清除。

- traceability:
  - Related: 本次使用者需求「勾選時左下角自動出現分析，且不想圖表外面再包一層」。

- next-actions:
  - N/A
