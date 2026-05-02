# 修正開啟地圖仍未顯示圖層（時序與索引） / Fix Open Map Layer Not Showing (Timing and Index)

## 2026-04-23 18:27

- objective:
  - 解決第一版修正後仍可能出現「開啟地圖但圖層未顯示」的殘留問題，補齊路由索引與地圖載入時序競態。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/composables/useMapLayerSidebarContent.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
- summary:
  - 將 Chat/AI Studio 的「開啟地圖」目標 index 改為 `map-layers-${city}`，避免落在不含目標圖層的 dashboard。
  - 在側欄 composable 新增 auto-open 穩定化：
  - 1) `openComponentId` 可從 `currentDashboard.components`、`contentStore.mapLayers`、`dashboardComponentsCache` 三路查找。
  - 2) 若 Mapbox style 尚未 ready，改為 `map.once("load", ...)` 延後啟圖層。
  - 3) 使用 `queuedOpenComponentId` 與 `activatedOpenComponentId` 避免重複觸發。
- change-type:
  - Fixed
- technical-details:
  - `useMapLayerSidebarContent.js` 新增：
  - `findOpenComponentById(openComponentId)`：多來源比對組件。
  - `activateOpenComponent(component, openComponentId)`：地圖 ready 後執行 `mapStore.addToMapLayerList(...)`。
  - `watch` 依賴擴充至 `contentStore.mapLayers.length` 與 `Boolean(mapStore.map)`，確保資料或地圖晚到也能補啟。
  - `ChatBox.vue`、`AIStudioChatPanel.vue` 將 `index` 改為 `map-layers-${city}`。
- verification:
  - 問題診斷：3 個修改檔均 `No errors found`。
  - 程式檢查：確認存在 `map.once("load", applyActivation)`、`findOpenComponentById` 與新的 `map-layers-${city}` 路由參數。
- performance-impact:
  - 新增 watcher 與一次性 `load` 事件綁定，負擔低。
  - 透過 queue/activated guard 避免重複 add layer。
- impact-risk:
  - 若 `openComponentId` 對應資料不存在或缺 `map_config`，仍會安全略過。
  - 若 Mapbox 實例被快速銷毀重建，需依現行生命週期重觸發 watcher（目前已有依賴 map 實例變化）。
- regression-test:
  - 從 ChatWidget 觸發地圖型組件，驗證進入 mapview 後圖層自動顯示。
  - 從 AI Studio 觸發同流程，驗證行為一致。
  - 驗證手動勾選/取消圖層仍可正常切換。
- traceability:
  - previous log: user-added/log/2026-04-23/1822-map-open-auto-activate-layer.md
- next-actions:
  - 建議執行一次端到端手測並記錄成功樣本 query。
