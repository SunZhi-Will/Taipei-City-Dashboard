# 內容區單卡縮小與切圖修正 / Focus View Minimize and Chart-Switch Fix

## 2026-04-17 13:47

- objective:
  - 修正右側內容區單卡模式下，缺少縮小返回與圖表切換能力的問題。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 調整右上角按鈕顯示條件，讓 `focus` 模式也顯示操作按鈕。
  - 調整控制列顯示條件，展開到內容區後仍保留圖表切換列。
  - 使使用者可在單卡模式中直接縮小返回網格，並切換不同圖表類型。

- change-type:
  - Fixed

- technical-details:
  - 將 header 按鈕區條件由 `['default', 'half', 'preview']` 擴充為 `['default', 'half', 'preview', 'focus']`。
  - 移除控制列 v-if 條件中 `!expandedInContent` 限制，保留 `mode !== 'preview'` 判斷。
  - 保留原有 `expandLayout` 事件流，不影響父層切換內容區單卡模式。

- verification:
  - 執行語法/型別診斷：
    - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue`：No errors found
    - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`：No errors found
  - 檢查模板條件已更新（右上角按鈕與控制列顯示條件）。

- performance-impact:
  - 無額外資料請求與重算路徑。
  - 僅調整條件渲染，效能影響可忽略。

- impact-risk:
  - `focus` 模式按鈕顯示範圍擴大，若未來新增 mode 需同步檢查條件陣列。
  - 控制列在內容區單卡模式可見，若版面高度不足需再做樣式微調。

- regression-test:
  - 在 DashboardView 中點擊卡片右上角展開按鈕，確認進入內容區單卡模式。
  - 在單卡模式確認右上角可再次點擊縮小並返回網格。
  - 在單卡模式切換圖表種類，確認圖表切換正常。
  - 確認 preview 模式下仍不顯示控制列。

- traceability:
  - N/A

- next-actions:
  - 若需要，將相同內容區單卡模式擴展到 `MapView`（含 map/halfmap 版型）。
