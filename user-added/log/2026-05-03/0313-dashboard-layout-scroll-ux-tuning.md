# 儀表板卡片捲動與寬卡判定優化 / Dashboard Scroll and Wide-Tile Heuristic Tuning

## 2026-05-03 03:13

- objective:
  - 解決儀表板卡片內仍出現滑輪（垂直捲動）影響閱讀連續性。
  - 調整首列卡片過寬問題，避免第一格不必要地跨欄。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 移除以 `map_config` 判定寬卡的條件，僅保留寬圖型（timeline/heatmap/metro/treemap）觸發跨欄。
  - 將基準列高由 `170px` 提升為 `180px`，增加卡片可用垂直空間，降低內容擠壓。
  - 在 dashboard tile 層覆寫 chart/loading/error 區塊捲動行為：關閉 `overflow-y`，保留 `overflow-x`。

- change-type:
  - Changed

- technical-details:
  - `getTileClass()` 內移除 `hasMapLayer` 邏輯，避免僅因含地圖設定就被套用 `dashboard-tile--wide`。
  - `.dashboard` 的 `grid-auto-rows` 由 `170px` 調整為 `180px`。
  - `.dashboard-tile` 的 deep selector 針對 `.dashboardcomponent-chart/.loading/.error` 增加：
    - `overflow-y: hidden !important`
    - `overflow-x: auto`

- verification:
  - 執行 VS Code 診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`，結果 `No errors found`。
  - 靜態檢查規則變更：確認寬卡觸發條件不再包含 map layer。

- performance-impact:
  - 變更僅屬 CSS 與前端判斷條件，執行成本極低。
  - 移除垂直捲動可減少使用者在卡片內滾動操作，提升掃讀效率。

- impact-risk:
  - 部分過於密集的圖表在關閉垂直捲動後，可能改以內容壓縮顯示。
  - 若後續新增特殊圖型，可能需擴充寬卡/高卡型別清單。

- regression-test:
  - 驗證「台北食品安全」頁首第一張卡是否回到一般寬度（非跨兩欄）。
  - 驗證各卡片內是否不再出現垂直滑輪。
  - 驗證手機版（<=768）仍維持單欄與可讀性。

- traceability:
  - Related request: 使用者回報「裡面還是有滑輪，且第一格不用那麼寬」。

- next-actions:
  - 若需要更精準視覺節奏，可再加入「首列禁止寬卡」規則或每個 dashboard 的客製化 layout profile。
