# 輪播中顯示真實 Mapbox 地圖 / Real Mapbox Map in Presentation Carousel

## 2026-05-02 16:30

- objective:
  - 地圖投影片（type="map"）在 Presentation 模式只顯示 DashboardComponent 圖例面板，而非真實地圖
  - Hero 投影片被強制出現在開頭/結尾，投影片數量也是固定模板，缺乏彈性

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - **持久地圖層架構**：MapContainer 從 `v-show="selectedMode==='map'"` 移到 `aistudio-canvas` 內的絕對定位層 `canvas-persistent-map`（z-index: 1），永遠掛載（當有地圖數據時）。`canvas-body` 加 `z-index: 2; isolation: isolate` 建立 stacking context
  - **地圖 slide 透明化**：map 投影片不再使用 `slide-glass-panel`，改為直接用 `slide-map-overlay`（全覆蓋透明層 + 底部漸層信息欄），玻璃面板完全移除，讓 z-index 1 的 MapContainer 透穿顯示
  - **emit 通知**：AIStudioPresentationCanvas 新增 `emit('map-slide-active', boolean)`，在 `watch(activeIndex)` 時觸發；AIStudioView 監聽並控制 `canvas-persistent-map--visible` 的 CSS class
  - **AI prompt 彈性化**：移除「必須以 hero 開頭/結尾」的強制規定，改為「可選」；移除固定模板，強調投影片數量由主題決定（建議 3-10 張）；同時明確告知 AI「map slide 顯示真實 Mapbox 互動地圖」

- change-type:
  - Fixed
  - Changed

- technical-details:
  - Z-index 架構：aistudio-canvas(relative) → canvas-persistent-map(absolute, z-index:1) + canvas-body(z-index:2, isolation:isolate)
  - 透明穿透：map slide 的 .presentation-slide--map { padding:0 }、不包 .slide-glass-panel，所以 z-index:2 stacking context 內完全透明 → 露出 z-index:1 的 MapContainer
  - 非地圖投影片：.slide-glass-panel background:rgba(15,23,42,0.84) 仍覆蓋 slide 區域，視覺不受影響
  - canvas-persistent-map 可見條件：selectedMode==='map' OR (selectedMode==='presentation' AND isMapSlideActive)
  - shouldMountMap 條件：hasMapComponents OR hasMapSlides（避免多餘的 MapContainer mount）
  - syncMapLayersForSlide 仍在 activeIndex watcher 中運作，確保地圖圖層和定位都在 map slide 切換時更新

- verification:
  - `docker exec ... go build ./...` → ✅ BUILD OK
  - `docker exec ... go test ./app/services/ai/...` → ✅ PASS
  - VSCode lint check: AIStudioView.vue, AIStudioPresentationCanvas.vue → ✅ No errors

- performance-impact:
  - MapContainer 改為持久掛載（shouldMountMap=true 時），避免切換模式時重新初始化 Mapbox GL（節省約 0.3-1s 的地圖初始化時間）
  - map slide 移除 DashboardComponent 渲染（不再 render MapLegend.vue），輕量化

- impact-risk:
  - **地圖初始化時機**：MapContainer 現在在 shouldMountMap=true 時就掛載，早於切換到 map 模式。mapStore.map 會提前初始化。需確認不影響其他 map 相關功能
  - canvas-body 加 isolation: isolate 可能影響其他 compositing 效果（如 backdrop-filter 的穿透），但 slide-glass-panel 的 backdrop-filter 是 within stacking context，應不受影響
  - 非地圖投影片 slide padding 外側的背景：canvas-inner--presentation 無背景色，顯示 aistudio-right 的 $bg。暗色主題下不明顯，亮色主題略有細框效果

- regression-test:
  - 在 AI Studio 請 AI「做含地圖的空氣品質簡報」→ 輪播中的 map slide 應顯示真實 Mapbox 地圖，非 MapLegend 面板
  - 切換到「地圖」模式 → 地圖仍正常顯示（canvas-persistent-map 仍 visible）
  - 非地圖投影片（hero, text, component）→ 外觀正常，不受影響
  - 只有單一 component 類組件（無 map）→ 不出現 map slide，shouldMountMap 可能為 false → MapContainer 未掛載（驗證不 crash）
  - 投影片數量：AI 應能生成 1 張或多張，不強制 hero 開頭/結尾

- traceability:
  - 相關 log：user-added/log/2026-05-02/1554-map-chart-type-case-fix.md
  - 端對端測試揭示此問題（AI 生成 display_plan 後，map slide 顯示 DashboardComponent 而非地圖）

- next-actions:
  - 瀏覽器視覺確認：開啟 AI Studio 實際測試 map slide 是否顯示地圖
  - 驗證地圖圖層（syncMapLayersForSlide）在 map slide 切換時正確顯示對應組件的地圖數據
  - 若需要也可在 map slide 底部加入 compact MapLegend 小面板（optional enhancement）
