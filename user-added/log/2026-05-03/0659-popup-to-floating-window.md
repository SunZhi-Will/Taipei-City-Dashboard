# Popup 改為可拖曳縮放浮動視窗 / Convert Popup to Draggable Resizable Floating Window

## 2026-05-03 06:59

- objective:
  - 將地圖組件的放大視窗（dc-popup）從 modal overlay 彈跳視窗改為可拖曳、可縮放的浮動視窗，移除背景模糊遮罩

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 移除 `.dc-popup-overlay` wrapper div 及其背景模糊（backdrop-filter: blur）遮罩
  - 移除進場動畫（dc-popup-fade、dc-popup-scale keyframes）
  - `.dc-popup` 改為 `position: fixed; z-index: 9999; resize: both`，預設尺寸與原本相同
  - 加入 JS 拖曳邏輯：`onDragStart / onDragging / onDragEnd`，透過 `mousedown` 在 header 啟動，`window` mousemove/mouseup 追蹤
  - 每次 `showPopup` 變為 true 時，自動計算視窗置中座標（`popupPos`）
  - 拖曳時設 `document.body.style.userSelect = 'none'`，結束後還原，防止拖曳選取文字
  - header 加 `cursor: move`；拖曳中以 `.dc-popup--dragging * { cursor: grabbing !important }` 覆蓋

- change-type:
  - Changed

- technical-details:
  - `popupPos: ref({x, y})` 儲存浮動視窗左上角座標，透過 `:style` 綁定 `left/top`
  - `resize: both` 配合 `overflow: hidden` 使瀏覽器原生縮放控制可用（右下角拖柄）
  - `min-width: 320px; min-height: 240px` 防止縮太小導致內容不可見
  - 點擊關閉按鈕的邏輯：`onDragStart` 中以 `e.target.closest('.dc-popup-close')` 早期返回，不干擾關閉操作

- verification:
  - `get_errors` 回傳 "No errors found"
  - 目測 template 結構：overlay wrapper div 已移除，dc-popup 直接在 Teleport 內
  - CSS 確認：`.dc-popup-overlay` 及兩個 keyframe 已刪除；`.dc-popup` 已加 position/resize/min-size

- impact-risk:
  - 影響範圍：所有 `mode.includes('map')` 組件的 expand 視窗
  - 風險：resize 行為依賴瀏覽器原生，各 OS/瀏覽器縮放手柄外觀略有差異
  - 無資料邏輯變更，不影響圖表渲染

- regression-test:
  - 開啟地圖組件 → 點擊放大按鈕 → 確認視窗在畫面中央出現（無遮罩）
  - 拖曳 header → 視窗應隨滑鼠移動
  - 拖曳右下角 → 視窗應可縮放，內容 chart 自動 resize
  - 點擊關閉按鈕 → 視窗應正確關閉
  - 拖曳後再次開啟 → 視窗應重新置中

- traceability:
  - N/A

- next-actions:
  - 若需要 touch 裝置支援，可補 touchstart/touchmove/touchend 事件
  - 可考慮記憶上次視窗位置（localStorage）
