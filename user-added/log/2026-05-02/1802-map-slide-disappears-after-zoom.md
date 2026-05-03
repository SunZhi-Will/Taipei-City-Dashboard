# 地圖投影片縮放後消失修正 / Fix Map Slide Disappearing After Zoom

## 2026-05-02 18:02

- objective:
  - 修正 AI Studio 簡報模式中，地圖投影片（map slide）在 Mapbox 縮放或瀏覽器縮放後地圖消失的問題

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 在 `.presentation-canvas:has(.presentation-slide--map.is-active)` 選擇器下新增三條 CSS 規則：
    1. `perspective: none` — 停用 3D perspective context
    2. `.presentation-track { transform-style: flat; }` — 將 preserve-3d 改回 flat（2D）
    3. `.presentation-slide--map.is-active { transform: none; transition: opacity 0.8s ease; }` — 移除 active map slide 的 translateZ(0) transform
  - 根本原因：`transform-style: preserve-3d` + `perspective: 1200px` 在縮放觸發重繪（repaint）時，會將 presentation layer 提升為 GPU composite layer。這個 composite layer 的透明區域在與底層 Mapbox WebGL canvas composite layer 合成時，瀏覽器以隱式不透明背景填充而非穿透顯示下層 map，導致地圖消失。
  - 修正方向：當 map slide 為 active 時，停用 3D compositing context，確保透明鏈（presentation canvas → stage → slide-glass-panel → viewport）以 2D compositing 正確穿透到 z-index:1 的 MapContainer 層。

- change-type:
  - Fixed

- technical-details:
  - `.canvas-body` 有 `isolation: isolate`，建立一個 stacking context，內含 z-index:1 的 `.canvas-persistent-map`（Mapbox）和 z-index:2 的 `.canvas-inner--presentation`
  - 透明鏈依賴 CSS z-index compositing：上層透明元素讓下層元素顯示
  - `transform-style: preserve-3d` 將 `.presentation-track` 的子元素提升到 3D GPU layer，3D layer 的透明區域在與另一個 GPU layer（Mapbox WebGL canvas）合成時，compositing API 可能填充隱式背景色而非穿透
  - `translateZ(0)` 雖然數值為零，在某些瀏覽器（特別是 macOS Metal 渲染路徑）仍會觸發 composite layer promotion
  - 修正後：map slide active 時整條 presentation stack 以 2D compositing 運行，透明穿透正常；非 map slide 時 3D 動畫效果不受影響（:has() selector 只在 map slide active 時生效）

- verification:
  - 打開 AI Studio → 進入有 map slide 的簡報模式
  - 在 map slide 上使用滾輪縮放 Mapbox 地圖，確認地圖不消失
  - 使用瀏覽器 Cmd+/Cmd- 縮放，確認地圖不消失
  - 切換到非 map slide 確認其他投影片的 3D 過場效果正常

- impact-risk:
  - 低風險：修改只在 map slide active 時生效（`:has()` selector）
  - 非 map slide 的 3D 過場動畫完全不受影響
  - map slide 的 opacity fade-in 動畫保留；只有 transform 動畫（scale/translateZ）在 active 狀態被移除

- regression-test:
  - 切換多張投影片（map ↔ 非 map）確認過場動畫正常
  - 在 map slide 上縮放地圖（scroll wheel, trackpad pinch）
  - 瀏覽器縮放（Cmd+/-）確認地圖存在
  - 確認 industry 主題（transport/senior-care/education/health）的 map slide 一樣正常

- traceability:
  - N/A

- next-actions:
  - N/A
