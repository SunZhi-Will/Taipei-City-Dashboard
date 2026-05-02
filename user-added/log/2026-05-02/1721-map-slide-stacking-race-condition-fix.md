# 地圖 Slide 顯示架構修正：z-index 堆疊與 Race Condition / Map Slide Architecture Fix: z-index Stacking & Race Condition

## 2026-05-02 17:21

- objective:
  - 修正 AI Studio Presentation 模式中，地圖 slide 填滿整個輪播（無框架）的問題
  - 修正地圖 slide 無標記點（syncMapLayersForSlide race condition）的問題

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - **問題 1：地圖填滿整個輪播（無框架）**
    - 根本原因：`canvas-persistent-map`（z-index:1, position:absolute）在 `canvas-body`（isolation:isolate）的 isolated stacking context 中，比非定位的 `canvas-inner--presentation` 層級更高（正 z-index 元素 > 非定位元素）。地圖被直接繪製在 presentation 上方，覆蓋整個區域。
    - 修正：給 `canvas-inner--presentation` 加上 `position: relative; z-index: 2`，使其高於地圖（z-index:1）。presentation canvas 繪製在地圖上方，透過其內部透明的 `slide-glass-panel--map` 讓地圖「露出」，而 `presentation-canvas` 和 `presentation-stage` 的 `background: #020617` 遮住卡片外部區域。
  - **問題 2：地圖無標記點（Race Condition）**
    - 根本原因：`syncMapLayersForSlide` 由 `watch(activeIndex, ..., { immediate: true })` 觸發。此時 `mapStore.map` 尚為 null（MapContainer 才剛掛載），`mapStore.map?.once?.(...)` 是 undefined，地圖層和座標定位永遠無法執行。
    - 修正：新增 `watch(() => mapStore.map, ...)` 監聽。當 `mapStore.map` 從 null 變為實際地圖物件時，若當前 slide 是 map 類型，重新執行 `syncMapLayersForSlide`。
  - **Map slide 樣式重構**
    - 舊設計：`slide-map-overlay`（absolute inset: 0），地圖完全填滿（但被地圖覆蓋無意義）
    - 新設計：`slide-glass-panel--map`（background: transparent, pointer-events: none），作為透明「洞口」。內部分為 header（標題+分頁）、viewport（透明填充）、footer（描述+位置標籤）三段。
  - **presentation-canvas 背景恢復**
    - 前次 session 將 `presentation-canvas` 改為 `background: transparent` 是錯誤的（導致地圖穿透整個 canvas 而非僅限卡片）。本次恢復為 `background: #020617`。
    - 同樣為 `presentation-stage` 加上 `background: #020617` 作為雙重保險。

- change-type:
  - Fixed

- technical-details:
  - **CSS Stacking Context（關鍵理解）**：
    - `canvas-body`（isolation: isolate）建立獨立 stacking context
    - 在此 context 內的繪製順序：非定位元素（flow）< z-index:auto 定位元素 < 正 z-index 元素
    - 修正前：`canvas-persistent-map`（z-index:1）> `canvas-inner--presentation`（非定位）→ 地圖蓋在 presentation 上方
    - 修正後：`canvas-inner--presentation`（z-index:2）> `canvas-persistent-map`（z-index:1）→ presentation 在地圖上方，透明 glass panel 露出地圖
  - **Transparent Glass Panel 穿透機制**：
    - `canvas-inner--presentation`（z-index:2）內的 presentation-canvas 有 `background: #020617`（不透明），presentation-stage 也有深色背景
    - 只有 `slide-glass-panel--map`（background: transparent）是透明的，精確對應 slide 卡片面積（即 `.presentation-slide` 的 padding 範圍內）
    - 因此地圖只在卡片內「透出」，卡片外被黑色背景遮住
  - **Race Condition 修正邏輯**：
    ```javascript
    // 新增 watcher：mapStore.map 從 null → 實例時重試
    watch(() => mapStore.map, (newMap) => {
      if (!newMap) return;
      const currentSlide = slides.value[activeIndex.value];
      if (currentSlide?.type === 'map') {
        syncMapLayersForSlide(currentSlide);
      }
    });
    ```
  - **syncMapLayersForSlide 防守邏輯重構**：
    - 新增 `setupMapLayers` 函式統一管理城市更新 + 圖層添加
    - `mapStore.map?.loaded?.()` → 直接執行
    - `mapStore.map` 存在但未 loaded → `mapStore.map.once("load", ...)` 監聽
    - `mapStore.map === null` → 什麼都不做，等 `watch(() => mapStore.map)` 觸發
  - **pointer-events: none on glass panel**：確保 map slide 的點擊能（理論上）穿透到持久地圖層（在地圖在 z-index:1 的情境下），並防止 glass panel 誤攔截輸入
  - **Mapbox 控制項互動**：地圖在 z-index:1，被 canvas-inner--presentation (z-index:2) 覆蓋，carousel 模式下 Mapbox 原生縮放控制項不可互動（可接受，使用者可切換到 map 模式）

- verification:
  - `get_errors` on both files → No errors found
  - 架構邏輯驗證：
    - `canvas-body` isolated stacking context 確認 ✓
    - `canvas-inner--presentation` z-index:2 > `canvas-persistent-map` z-index:1 ✓
    - `presentation-canvas` background: #020617 ✓
    - `presentation-stage` background: #020617 ✓
    - `slide-glass-panel--map` background: transparent ✓
    - race condition watch handler 邏輯正確 ✓

- performance-impact:
  - 增加一個 `watch(() => mapStore.map)` watcher，僅在 mapStore.map 改變時觸發（通常只觸發一次），開銷極低
  - CSS z-index 變更無效能影響

- impact-risk:
  - **中低風險**：核心影響 AI Studio Presentation 的 map slide 顯示
  - `canvas-inner--presentation` 加了 `position: relative`，可能影響其內部元素的定位參考基準（但應無副作用，`presentation-canvas` 已是 `position: relative`）
  - 若未來有其他 canvas-inner 模式需要在地圖上顯示，也需要加 z-index:2
  - map mode（selectedMode === 'map'）：`canvas-persistent-map`（z-index:1）+ `canvas-inner--map`（非定位）→ 地圖顯示在 canvas-inner--map 上方，與預期一致（canvas-inner--map 幾乎為空）

- regression-test:
  - [ ] AI Studio → 生成包含 map slide 的 presentation
  - [ ] 地圖 slide 應顯示 Mapbox 地圖，且地圖只在卡片框架內（卡片外應為深色背景）
  - [ ] 地圖 slide 應顯示空氣品質監測站等標記點（mapConfig 圖層正確載入）
  - [ ] 地圖 slide 的 prev/next 導覽箭頭和 dots 分頁器應正常顯示且可點擊
  - [ ] 非 map slide（hero, text, component 等）不受影響
  - [ ] 切換至 map mode（selectedMode === 'map'）地圖正常全螢幕顯示
  - [ ] 切換至 components mode 無白屏或 z-index 異常

- traceability:
  - 承接本 session 前次修改（persistent map layer, glass panel architecture）
  - 相關 session log: user-added/log/（本 session 前段修改）

- next-actions:
  - 瀏覽器端實際測試 map slide 顯示效果（標記點、框架、導覽控制）
  - 若 Mapbox 標記點仍未顯示，檢查 `mapStore.marker` 物件是否在地圖初始化後才建立
  - 考慮在 map slide footer 加「切換至地圖模式」按鈕（emit switch-to-map）讓使用者能互動地圖
