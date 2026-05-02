# 地圖左側面板佈局衝突修正 / Map Left Panel Layout Conflict Fix

## 2026-05-03 04:30

- objective:
  - MapLayerSidebar 與 MapAnalysisPanel 同時顯示時，兩者皆以 `position: absolute; left: 12px` 佔用相同左側區域，導致 sidebar 底部與 analysis panel 重疊衝突。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue

- summary:
  - 在 `MapView.vue` 新增 `.map-left-column` flex 容器，將 `MapLayerSidebar` 與 `MapAnalysisPanel` 包裹為同一左側欄
  - `.map-left-column` 以 `position: absolute; top: 68px; left: 12px; bottom: 12px; display: flex; flex-direction: column; gap: 8px` 定義，完整佔用左側可用高度
  - `MapLayerSidebar` 的 `.map-island-shell` 改為 `position: relative; flex: 1 1 auto; min-height: 0`，`max-height` 從固定值改為 `100%`，彈性填充剩餘空間
  - `MapAnalysisPanel` 的 `.map-analysis-panel` 改為 `position: relative; flex-shrink: 0`，固定在欄底部
  - 原本 sidebar `z-index: 20`、analysis panel `z-index: 21` 移至父容器統一管理，兩者不再需要互相競爭 z-index

- change-type:
  - Changed

- technical-details:
  - 原始問題：sidebar `top: 68px` + `max-height: calc(100vh - 80px)` 實際高度幾乎貼底；analysis panel `bottom: 12px` + `height: min(360px, 42vh)` 從底部往上推，兩者重疊區域為 `min(360px, 42vh) - 12px`
  - 修正後：flex 欄高 = `calc(100vh - 68px - 12px)` = `calc(100vh - 80px)`，與原 sidebar 最大高度一致；analysis panel 開啟時，sidebar 自動縮減至 `欄高 - 8px gap - analysis panel 高度`
  - `pointer-events: none` 設定在父容器，子元素再設 `pointer-events: auto`，確保地圖底層仍可接收滑鼠事件

- verification:
  - 瀏覽 http://localhost:8080/map，開啟食品業者衛生稽查地圖，點選「分析」按鈕 → MapAnalysisPanel 應顯示於 sidebar 下方，無重疊
  - 縮放瀏覽器視窗確認 sidebar 高度隨 analysis panel 開啟/關閉動態調整
  - 折疊 sidebar（< chevron）確認 analysis panel 仍可獨立正常顯示

- impact-risk:
  - 影響範圍：MapView 地圖頁左側 UI，僅限桌面（兩個組件皆有 `hide-if-mobile`）
  - 無已知回歸風險；sidebar 折疊動畫、toggle button 相對定位均不受影響

- regression-test:
  - [ ] sidebar 折疊/展開動畫正常
  - [ ] analysis panel 開啟/關閉不留殘影
  - [ ] 地圖底層點擊（zoom、pan）不受 pointer-events 阻擋
  - [ ] 無 analysis panel 時 sidebar 填充全欄高度

- traceability:
  - N/A

- next-actions:
  - 若 analysis panel 需比 sidebar 更寬（min(340px,30vw) > 260px），考慮統一欄寬或讓 panel 向右超出
