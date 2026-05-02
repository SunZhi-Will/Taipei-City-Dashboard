# 圓餅圖地圖視圖數值同步修正 / DonutChart Map-View Data Sync Fix

## 2026-05-03 06:10

- objective:
  - 修正「食品業者衛生稽查地圖」卡片視圖與地圖展開視圖的圓餅圖數值完全不同的問題
  - 卡片視圖顯示 13,695 筆（SQL 全期匯總），地圖展開顯示 387 筆（僅 2026-04 單月）

- files:
  - Taipei-City-Dashboard-FE/src/store/mapStore.js
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue

- summary:
  - 移除 mapStore 載入 GeoJSON 時的自動 `timeStore.setMonth(months[0])` 呼叫
  - 修改 DonutChart `geoRawData` 邏輯：`selectedMonth = null` 時回傳 `null`，fallback 回 `props.series`（SQL API 資料）
  - 結果：地圖初始開啟時兩個圓餅圖數值一致；動畫播放或拖動滑桿時仍動態顯示對應月份資料

- change-type:
  - Fixed

- technical-details:
  - **Root cause 鏈**：
    1. `DashboardComponent.vue:484` → `:map_filter_on="mode.includes('map')"` 地圖展開時傳 `true`
    2. `DonutChart.vue:isMapLinkedMode` = `map_filter_on && map_config[0].index` 都為真 → 切換 GeoJSON 模式
    3. `mapStore.js:545` 地圖載入 GeoJSON 後自動呼叫 `timeStore.setMonth(months[0])` = `'2026-04'`
    4. `DonutChart.geoRawData`：`selectedMonth` 有值 → 讀 GeoJSON `month_stats['2026-04']` = {合格:295, 複查:92} → 總計 387
  - **修正 1（mapStore.js）**：移除 `timeStore.setMonth(months[0])`，保留 `map.setFilter()` 讓地圖視覺上仍顯示最新月份
  - **修正 2（DonutChart.vue）**：`geoRawData` 在 `selectedMonth = null` 時直接 return null，不再 aggregate GeoJSON，讓 `parsedSeries` fallback 回 `props.series`（SQL）
  - **GeoJSON vs SQL 數值差異說明**：GeoJSON `month_stats` 全期彙總 ≠ SQL query 結果（分類定義不同），因此不能直接用 GeoJSON aggregate，必須 fallback 回 SQL

- verification:
  - 地圖初始載入：`timeStore.selectedMonth === null` → `geoRawData returns null` → `parsedSeries` 讀 `props.series` → 與卡片視圖同
  - 動畫播放：`mapStore.animateMonths()` → `timeStore.setMonth(month)` → `geoRawData` 回對應月份 → 動態更新 ✓
  - 滑桿拖動：`mapStore.setMapMonth()` → `timeStore.setMonth(month)` → 同上 ✓
  - 可透過瀏覽器開啟 `/food_safety_tpe` 儀表板，展開「食品業者衛生稽查地圖」地圖比對兩個圓餅圖數值

- performance-impact:
  - 無額外 API 呼叫，移除了一次 GeoJSON 全期 aggregate 計算

- impact-risk:
  - 僅影響含 `_animate` 屬性的月份型 GeoJSON 圖層（目前僅 `taipei_imap_food`）
  - 停止動畫後 `selectedMonth` 殘留於最後播放月份，DonutChart 仍顯示該月資料（非 aggregate）；此為預期行為，不影響初始同步需求

- regression-test:
  - 開啟食安儀表板，確認 `taipei_imap_food` 圓餅圖卡片視圖與地圖展開初始值一致
  - 點擊播放 → 確認圓餅圖動態更新各月份
  - 拖動滑桿 → 確認圓餅圖跟隨月份切換
  - 切換至「動態長條圖」再切回「圓餅圖」→ 確認若 `selectedMonth` 有值時圓餅圖顯示對應月份

- traceability:
  - N/A

- next-actions:
  - 可考慮在 `stopMonthAnimation()` 呼叫後 reset `selectedMonth = null`，讓停止動畫後自動回到全期 aggregate
  - 優先級：低（目前行為可接受）
