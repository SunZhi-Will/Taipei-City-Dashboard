# AI Studio 輪播擴頁與地圖投影片修正 / AI Studio Carousel Expansion and Map Slide Support

## 2026-04-24 11:39

- objective:
  - 修正 AI Studio 輪播僅顯示 4 頁（hero + 3）導致與圖表牆數量不一致的問題。
  - 讓具 map_config 的組件可在輪播模式中以地圖投影片顯示。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 移除輪播 fallback 的 components.slice(0, 3) 限制，改為納入所有可用組件。
  - 當 scene 已含 explicit slides 時，會自動補上尚未被納入的組件投影片，避免輪播頁數少於圖表牆。
  - 新增 map 投影片型別判斷（依 dashboardConfig.map_config），在輪播中渲染地圖容器。
  - 切換到 map 投影片時，自動同步地圖視角與圖層（updateMapViewForCity + addToMapLayerList）。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 `hasMapConfig`、`buildAutoComponentSlides`、`toSlideComponentId`，統一 slide 與 component 的映射。
  - `componentById` 改為以字串化 ID 存取，降低字串/數字 ID 比對失敗風險。
  - `getSlideComponent` 擴充支援 `component` 與 `map` 兩類投影片。
  - 新增 `syncMapLayersForSlide` 於 active slide 變更時注入 map layer；若 map 已載入則立即執行，否則掛載 load 事件後執行。
  - 模板新增 map 投影片區塊，僅在 active slide 掛載 `MapContainer`，避免多實例衝突。

- verification:
  - 檔案診斷檢查：`get_errors` for `Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue` → No errors found。
  - 邏輯檢查：確認輪播生成邏輯不再使用 `slice(0, 3)`，且 explicit slides 會附加缺漏組件投影片。

- performance-impact:
  - 輪播頁數增加後，投影片節點數量上升，長清單下初始渲染成本可能增加。
  - map 投影片僅 active 時才掛載地圖容器，可降低非顯示頁的地圖初始化負擔。

- impact-risk:
  - map 投影片切換時會初始化/清理地圖，若頻繁切換可能增加 Mapbox 資源切換成本。
  - 若外部資料 map_config 缺漏或格式不完整，map 投影片會退化為不渲染地圖（已有防呆判斷）。

- regression-test:
  - 在 AI Studio 輸入可回傳 6+ 組件的查詢，確認輪播頁數 >= 圖表組件數量 + hero（或 explicit slides + 缺漏補齊）。
  - 確認含地圖組件時，輪播中可看到地圖投影片且圖層正確載入。
  - 切換到圖表牆模式與地圖模式，確認既有功能未受影響。
  - 驗證全螢幕模式下輪播切換與 map slide 顯示正常。

- traceability:
  - N/A

- next-actions:
  - P1: 若地圖投影片切換成本偏高，可加入 map instance 保活機制與圖層差量更新。
  - P2: 增加 e2e 測試覆蓋「explicit slides + 缺漏補齊」行為。
