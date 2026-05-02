# 地圖頁新增地址與座標搜尋定位 / Add Address and Coordinate Search for Map Page

## 2026-04-24 14:53

- objective:
  - 在地圖頁下方新增搜尋功能，支援輸入地址或座標，讓使用者可快速移動畫面到目標位置。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 在地圖頁加入底部搜尋列，提供地址與座標兩種輸入方式。
  - 座標輸入支援 `lng,lat` 與 `lat,lng` 形式，並自動解析。
  - 地址輸入透過 Mapbox Geocoding API 取得第一筆結果後，執行地圖 flyTo 並放置 marker。
  - 新增成功/失敗/提示通知，改善使用者操作回饋。

- change-type:
  - Added

- technical-details:
  - 新增 `locationQuery` 與 `isLocating` 狀態管理搜尋文字與定位中狀態。
  - 新增 `parseCoordinateInput(rawInput)`：
    - 統一全形標點為逗號後拆詞。
    - 驗證輸入為兩個數值且在合法經緯度範圍內。
    - 自動判斷 `lng,lat` 或 `lat,lng`。
  - 新增 `moveMapToLocation(lng, lat)`：
    - 使用 `mapStore.map.flyTo` 平滑移動至目標位置。
    - 若 `mapStore.marker` 存在，同步更新 marker 到目標位置。
  - 新增 `handleLocationSearch()`：
    - 優先嘗試座標解析。
    - 若非座標，改呼叫 Mapbox Geocoding API (`mapbox.places`) 查詢地址。
    - 以 `dialogStore.showNotification` 回報結果。
  - 介面新增於 `MapContainer` 底部，含 input、按鈕、Enter 觸發搜尋與 loading disabled 狀態。

- verification:
  - 執行 VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。
  - 人工檢查：
    - 確認模板已綁定 `v-model`、`@keydown.enter.prevent`、`@click`。
    - 確認定位流程同時覆蓋座標與地址路徑。

- performance-impact:
  - 平時無額外輪詢或背景任務。
  - 僅在使用者觸發搜尋時發出一次 geocoding request，對整體效能影響低。

- impact-risk:
  - 風險：地址搜尋依賴 `VITE_MAPBOXTOKEN` 與外部 geocoding 服務可用性。
  - 緩解：已加入 token 缺失與 API 失敗通知，避免靜默失敗。

- regression-test:
  - 測試輸入 `121.5654,25.0330` 可定位到台北 101 附近。
  - 測試輸入 `25.0330,121.5654` 仍可正確定位。
  - 測試輸入地址關鍵字（如 `台北101`）可定位。
  - 測試空值與無效輸入會顯示提示通知。
  - 測試手機版（<=768px）搜尋列顯示與可操作性。

- traceability:
  - N/A

- next-actions:
  - P1: 若需要可進一步加入下拉候選結果清單（autocomplete）。
  - P2: 可加入「最近搜尋紀錄」與「定位後動畫高亮」提升可用性。
