# 地圖模式狀態隔離與側欄分析圖示修正 / Map-Mode State Isolation and Sidebar Analysis Icon Fix

## 2026-05-03 05:33

- objective:
  - 深度修正切換地圖後回到儀表板時，Donut 圖表狀態與動畫被污染導致行為異常。
  - 修正地圖左側清單互動：無地圖資料不可勾選，但仍可進入分析。
  - 將「分析」文字按鈕改為開啟圖示按鈕。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue

- summary:
  - 將 Donut 圖表的 GeoJSON 月份同步邏輯限制為 map mode 才啟用，避免地圖頁時間狀態回寫到一般儀表板圖表。
  - 將 AnimatedColumnChart 的 map month 同步也限制為 map mode，避免跨頁共享 `selectedMonth` 造成後續圖表呈現異常。
  - 側欄中的無地圖組件 checkbox 改為 disabled，不再允許誤勾選；但分析入口保留且可用。
  - 分析按鈕改為 icon（`open_in_new`），符合「開啟分析」語意。
  - 分析面板在無 map_config 時改用 `default` 模式顯示，避免出現地圖 toggle 造成使用者混淆。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - DonutChart:
    - 新增 `isMapLinkedMode = map_filter_on && mapSyncIndex`。
    - `geoRawData`、`availableMonths`、`togglePlay`、`onSliderInput` 全面加上 map mode 條件。
    - 新增 `watch(map_filter_on)`，離開 map mode 時主動停止月份動畫，避免殘留 interval。
  - AnimatedColumnChart:
    - 新增 `map_filter_on` prop。
    - `applyMonth` 中僅在 `canSyncMapMonth` 時呼叫 `setMapMonth`。
    - unmount 時僅在 map mode 才呼叫 `stopMonthAnimation`。
  - MapDashboardListSection:
    - checkbox 加上 `:disabled="!hasMapConfig(component)"`。
    - 分析按鈕改為圓形 icon button，圖示為 `open_in_new`。
  - useMapLayerSidebarContent:
    - `handleComponentAnalyze` 移除「無 map_config 不可分析」阻擋，允許開啟分析面板。
  - MapAnalysisPanel:
    - 新增 `panelHasMapConfig`。
    - `DashboardComponent` 依 `panelHasMapConfig` 在 `map/default` 模式間切換。

- verification:
  - VS Code diagnostics 檢查以下檔案皆為 `No errors found`：
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue`
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue`
    - `Taipei-City-Dashboard-FE/src/components/map/MapDashboardListSection.vue`
    - `Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js`
    - `Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue`

- performance-impact:
  - 將月份同步限制於 map mode 可降低非地圖頁不必要的 reactive 計算與狀態同步。
  - 側欄 icon 按鈕替換不增加可感知渲染成本。

- impact-risk:
  - 若既有流程依賴「非 map mode 也讀 GeoJSON 月份統計」將改為回到 API series 呈現；此為本次刻意行為以隔離狀態。
  - 無 map_config 組件可進分析後，分析面板會以 chart-only 呈現，不會驅動地圖圖層。

- regression-test:
  - 進 dashboard 觀察 Donut 外觀與動畫，切到 map 再切回 dashboard，確認不再出現地圖月份 slider/播放殘留。
  - map 左側對「無地圖」組件：checkbox 應 disabled。
  - map 左側對「無地圖」組件：點擊開啟 icon 可進入分析面板。
  - map 左側對「有地圖」組件：checkbox 與分析 icon 皆可正常使用。

- traceability:
  - related request: 使用者回報「兩個問題都沒有解決，且左邊無資料要不能勾但可分析，分析改開啟 icon」。

- next-actions:
  - 建議補一個 E2E：覆蓋 dashboard↔map 來回後 Donut 不應出現 map month controls 的情境。
