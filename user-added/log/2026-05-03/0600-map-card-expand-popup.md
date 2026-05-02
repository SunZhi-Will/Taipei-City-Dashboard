# 地圖卡片展開彈窗按鈕 / Map Card Expand Popup Button

## 2026-05-03 06:00

- objective:
  - 在地圖模式組件卡片的 header toggle 區（開關旁邊）新增「展開視窗」按鈕
  - 點擊後在畫面中央彈出放大的彈跳視窗（overlay / lightbox），顯示相同圖表

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 新增 `showPopup` ref（預設 false）
  - 在 `dashboardcomponent-header-toggle`（map mode header）的 toggle switch 前插入 `dc-expand-btn` 按鈕
  - 新增 `<Teleport to="body">` 彈窗覆蓋層，包含：backdrop、置中面板、標題列（顯示組件名稱）、關閉按鈕（× / ESC 點 backdrop）、chart component 放大展示
  - popup 複用相同 `returnChartComponent(activeChart)` 與 `config.chart_data` 資料，只有 `map_filter_on=false` 避免觸發地圖篩選
  - 新增 `.dc-expand-btn`、`.dc-popup-overlay`、`.dc-popup` 等 SCSS 規則，含淡入/縮放 keyframe 動畫

- change-type:
  - Added

- technical-details:
  - `showPopup` ref 控制顯示，backdrop click-self 關閉
  - `<Teleport to="body">` 確保 z-index 不被組件容器 overflow:hidden 裁切
  - popup size: `min(860px, 88vw)` × `min(560px, 78vh)`，`backdrop-filter: blur(4px)`
  - 展開按鈕只在 `mode.includes('map')` 時顯示（在 `v-else-if="mode.includes('map')"` 分支中）
  - 移除了原本在 map header 中無實際效果的 `v-if="fullscreenBtn"` 舊 fullscreen-btn（因為 expandLayout emit 在 map mode 父層不處理）

- verification:
  - 語法正確（template/script/style 三段均無遺漏括號）
  - `activeSeries` 未定義問題已修正為 `config.chart_data`
  - `material-icons-round` 與既有 SCSS 規則一致（line 1022、1091 已有此選擇器）

- impact-risk:
  - 影響範圍：僅 `DashboardComponent.vue` map mode 組件卡片
  - 低風險：popup 為獨立 overlay，不影響主 layout 或其他模式
  - `map_filter_on=false` 避免 popup 中圖表誤觸發地圖篩選事件

- regression-test:
  - 開啟含地圖組件的儀表板，確認 header 右側 toggle 旁出現展開按鈕圖示
  - 點擊展開按鈕，確認背景變暗、中央彈出面板並顯示圖表
  - 點擊背景遮罩或右上角 × 關閉彈窗
  - 確認非 map mode（default、half、focus 等）不顯示展開按鈕
  - 確認 toggle 開關功能不受影響

- traceability:
  - N/A

- next-actions:
  - 若需支援 ESC 鍵關閉，可在 popup show 時加 `keydown.esc` 監聽
  - 若 popup 內 AnimatedColumnChart 的 timeline 需要獨立播放，可後續在 popup slot 傳入 isolated props
