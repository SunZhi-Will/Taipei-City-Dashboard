# 組件切換圖表型別殘留修復 / Fix Stale Active Chart Type on Component Switch

## 2026-05-03 05:35

- objective:
  - 修正地圖分析面板切換組件後，仍沿用前一個組件的 chart type，導致渲染錯誤圖表（例如誤顯示 AnimatedColumnChart）。
  - 修正 AnimatedColumnChart 對非時間序列資料誤判月份造成 `NaN` 顯示。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

- summary:
  - 在 DashboardComponent 新增 `config.id + chart types` 監聽，當組件切換時會重新校正 `activeChart` 至可用且優先的型別，避免舊值殘留。
  - 在 AnimatedColumnChart 增加 `YYYY-MM` 格式檢查，只對合法時間軸資料建立月份動畫；非時間資料不再進入月份流程。

- change-type:
  - Fixed

- technical-details:
  - DashboardComponent:
    - 新增 `watch(() => [props.config?.id, props.config?.chart_config?.types], ...)`。
    - 若當前 `activeChart` 不在新組件 `types` 內，或與 preferred type 不一致，強制重設。
    - preferred type 規則：`initialChartType` 合法時優先，否則用 `types[0]`。
  - AnimatedColumnChart:
    - 新增 `isYearMonth()` 驗證（`/^\d{4}-\d{2}/`）。
    - `monthlyData` 僅處理合法年月 `x` 值。
    - `formatMonthLabel()` 對非法值直接回空字串，避免顯示 `NaN`。

- verification:
  - VS Code diagnostics：
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` -> No errors found
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue` -> No errors found

- performance-impact:
  - 新增的 watcher 僅在 config/type 變更時觸發，運算成本低。
  - AnimatedColumnChart 加入字串格式檢查，對渲染效能影響可忽略。

- impact-risk:
  - 若某些特殊流程刻意依賴「跨組件保留 chart type」，本修正會改為以新組件合法型別為準。
  - 對非時間資料，AnimatedColumnChart 會更嚴格跳過月份邏輯，避免錯誤動畫。

- regression-test:
  - map 分析面板連續切換不同組件，確認不會沿用前組件圖型。
  - 針對食品業者衛生稽查地圖，確認不再出現「不合格 年 NaN 月」。
  - dashboard 與 map 來回切換後，圖表仍顯示該組件正確 chart type。

- traceability:
  - related request: 使用者回報「組件被修壞，應顯示圖表組件卻顯示錯誤動畫圖且月份 NaN」。

- next-actions:
  - 建議補一個單元測試：給 DashboardComponent 切換 config 後，`activeChart` 必須落在新 `types` 集合內。
