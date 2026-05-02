# AI Studio 地圖預載與投影片型別矯正 / AI Studio Map Preload and Slide Type Correction

## 2026-04-24 13:08

- objective:
  - 修正 AI Studio 地圖切換仍反覆重載的體感問題。
  - 修正輪播把非地圖重點圖表誤判為地圖投影片的問題。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 將地圖模式改為單一 MapContainer 常駐掛載（由 `v-show` 控制可見性），達成進入頁面後預載、模式切換不重建。
  - 輪播自動投影片規則改回一律 `component`，不再僅因 `map_config` 就自動轉成地圖投影片。
  - 地圖型投影片改為預載提示視圖，避免在輪播頁內每次切頁重建地圖容器造成重載。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `AIStudioView.vue`:
    - 新增 `hasMapComponents` 計算屬性，判斷目前推薦組件是否含可用 map layer。
    - `map` 模式下由 `MapContainer v-if="hasMapComponents"` 掛載，並因父層 `v-show` 常駐，達到一次初始化、重複使用。
    - 空狀態訊息調整為「目前推薦內容沒有可顯示的地圖圖層」，避免誤導為需先去其他頁初始化。
  - `AIStudioPresentationCanvas.vue`:
    - `buildAutoComponentSlides` 改為固定 `type: "component"`，停止自動 map slide 轉換。
    - 移除輪播內 `MapContainer` 的即時掛載行為，改為 map slide 佔位提示文案，避免地圖重建。

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found
  - 邏輯確認:
    - 僅保留單一 MapContainer 實例（map 模式）以避免雙實例互相重置。
    - 輪播自動生成不再把含 map_config 的圖表誤判成 map slide。

- performance-impact:
  - 地圖初始化集中於單次，模式切換時避免重建 Mapbox 實例，切換延遲顯著下降。
  - 輪播切頁移除地圖重掛載，降低 CPU 與資源抖動。

- impact-risk:
  - 中低風險：若使用者期待輪播中直接顯示可互動地圖，現行改為提示視圖，需要切到地圖模式查看。
  - 風險可控：此策略優先滿足「不重載」目標。

- regression-test:
  - 在 AI Studio 來回切換「圖表牆 / 地圖 / 輪播」確認地圖不再每次重建。
  - 驗證輪播自動生成頁面中，非地圖重點圖表不再被渲染為地圖頁。
  - 驗證有地圖組件時，切到地圖模式可正常顯示地圖與圖層。

- traceability:
  - N/A

- next-actions:
  - P1: 若要恢復「輪播中直接顯示地圖」且維持不重載，建議下階段做單一 map host + 視圖投影方案（共享同一 Mapbox 實例）。
