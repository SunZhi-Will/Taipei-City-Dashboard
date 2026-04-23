# MapView 地圖交叉比對 UI/UX 全面改善 / MapView Cross-Map UI/UX Overhaul

## 2026-04-23 14:16

- objective:
  - 解決 MapView 三區塊混疊、地圖空間太小、切換區塊造成畫面混亂的問題
  - 讓使用者可收合左側面板以最大化地圖視野
  - 將三個語意不同的區塊（主題圖層、基本圖層、純資料組件）改為 Tab 切換，降低視覺噪音

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - **Script 層**: 新增 `panelCollapsed` ref（控制收合狀態）、`activeTab` ref（'theme'|'basic'|'nomap'），route 切換時重設 activeTab
  - **Template 層 - 面板包裝**: 將原 `.hide-if-mobile` div 重構為 `.map-panel`（flex row wrapper）+ `.map-panel-body`（flex col content）+ `.map-panel-toggle`（收合按鈕）三層結構
  - **Template 層 - Tab 導航**: 在正常儀表板（非 map-layers、有組件）時，於面板頂部渲染 `map-tabs`，含主題圖層/基本圖層/純資料三個 tab，各附數量 badge
  - **Template 層 - 分頁內容**: 原案例 2 的三個線性區塊（hasMap、mapLayers、noMap）改用 `<template v-if="activeTab === ...">` 條件渲染，每次只顯示一個分頁內容
  - **CSS 重構**: 移除 `.map` 的 `&-charts` 嵌套，改為獨立的 `.map-panel`、`.map-tabs`、`.map-charts`，各自負責對應的 flex 佈局
  - **AED Overlay 相容**: `.map-overlay-panel` CSS 改為針對 `.map-panel-body` 設定 absolute 定位，行為與原來一致
  - **halfmapopen 高度**: `DashboardComponent.vue` 的 `.halfmapopen` 從固定 `height: 200px` 改為 `height: auto; max-height: 220px`，支援動態內容高度

- change-type:
  - Changed

- technical-details:
  - `.map-panel` 採用 `display: flex; flex-direction: row; flex-shrink: 0`，確保地圖容器 `flex: 1` 正確佔滿剩餘寬度
  - `.map-panel-body` 的 `overflow: hidden` + `transition: width 0.25s ease` 實現平滑收合動畫；收合時 `width: 0; opacity: 0; margin-right: 0`
  - Tab 系統使用獨立 `v-if`（非 `v-else-if`）避免 Vue 3 v-if chain 被 HTML 注解打斷的問題
  - `hide-if-mobile` class 移至 `.map-panel` 最外層，確保在 ≤1000px 螢幕上整個面板（含收合按鈕）均隱藏
  - Tab badge 使用 `rgba(255,255,255,0.18)` 背景 + `inherit` 色彩，active tab 時 badge 隨高亮色變化
  - `.map-charts` 改為 `flex: 1; min-height: 0; align-content: start`，在 flex column 父容器中正確填滿剩餘高度並從頂部開始排列

- verification:
  - `get_errors` 工具確認 MapView.vue 無 TypeScript/ESLint 錯誤
  - DashboardComponent.vue halfmapopen 修改已套用（height: auto; max-height: 220px）
  - 手動確認所有 5 個 cases（map-layers / 有組件 / loading / error / 無組件）仍在 template 中正確存在

- performance-impact:
  - Tab 切換使用 `v-if`（非 `v-show`）：未顯示的 tab 組件不渲染 DOM，減少初始渲染量
  - 面板收合動畫僅用 CSS transition，無 JS 計算，FPS 無影響
  - `map-panel-body` 的 overflow:hidden 在展開狀態不影響捲動

- impact-risk:
  - AED overlay 模式（isAedDashboard）：收合按鈕透過 `v-if="!isAedDashboard"` 隱藏，AED 佈局不受影響
  - map-layers 儀表板（case 1）：不渲染 Tab 導航，行為與原來一致
  - mobile ≤1000px：整個 .map-panel 仍透過 hide-if-mobile 隱藏
  - 若某 dashboard 無 hasMap 組件但有 basicLayer 或 noMap，初始顯示「主題圖層」tab 將為空白 → 次要 UX 風險，可後續加 computed defaultTab

- regression-test:
  - 測試一般儀表板：三個 tab 可正常切換，各 tab 顯示正確的組件清單
  - 測試面板收合：點擊 `<` 按鈕面板平滑收合，地圖展寬；點擊 `>` 恢復
  - 測試 AED overlay 模式（index 含 aed）：面板浮於地圖上，無收合按鈕
  - 測試 map-layers 儀表板：無 Tab 導航，所有圖層組件直接列出
  - 測試切換儀表板（route.query.index 變化）：activeTab 重設為 'theme'
  - 測試 mobile / RWD：面板隱藏，地圖全螢幕

- traceability:
  - N/A

- next-actions:
  - 若有空 tab 體驗問題，加入 computed `defaultTab` 自動跳至第一個有內容的 tab（優先級 P2）
  - 考慮加入面板寬度拖拉 resize handle（優先級 P3）
  - 待 Docker 重啟後在瀏覽器視覺驗證
