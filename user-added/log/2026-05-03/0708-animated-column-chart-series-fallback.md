# AnimatedColumnChart 無資料修正 / AnimatedColumnChart Empty Data Fix

## 2026-05-03 07:08

- objective:
  - 修正「食品中毒月度統計」（food_poisoning_trend）組件顯示「暫無可播放的月份資料」的問題

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - `activeChartSeries` computed 對 `AnimatedColumnChart` 只讀 `history_data?.[0]`，但 `food_poisoning_trend` 的 `history_config` 為 `null`，導致 contentStore 從不呼叫 `/history` endpoint，`history_data` 永遠是 undefined
  - `/chart` endpoint 已回傳正確格式的時間序列（月分為 series name，年份 Jan 1st 為 x 軸），`AnimatedColumnChart` 的 `monthlyData` 可直接解析
  - 修正：加入 `?? props.config.chart_data ?? null` fallback，讓無 `history_config` 的組件也能使用 `chart_data` 驅動動畫

- change-type:
  - Fixed

- technical-details:
  - 修改前：`return props.config.history_data?.[0] ?? null`
  - 修改後：`return props.config.history_data?.[0] ?? props.config.chart_data ?? null`
  - chart SQL 產生格式：`x_axis = (year || '-01-01')::timestamptz`，`y_axis = '01月'~'12月'`，`data = cases`
  - `AnimatedColumnChart.monthlyData`：`pt.x.slice(0,7)` = `"YYYY-01"` 作為每年的幀 key；12 個月各為一個 series name → 每幀顯示 12 根柱狀圖
  - fallback 不影響有 `history_config` 的組件（`history_data?.[0]` 優先取用）

- verification:
  - 瀏覽器開啟食安儀表板，「動態長條圖」改為顯示帶播放控制的年份動畫，而非「暫無可播放的月份資料」
  - `curl -s "http://localhost:8088/api/v1/component/47/chart?city=metrotaipei"` 確認回傳 12 個月份 series，x 值符合 `YYYY-01-01T...` 格式

- impact-risk:
  - 僅影響 `activeChart === 'AnimatedColumnChart'` 且 `history_data[0]` 為 undefined 時的分支
  - 其他圖表類型、有 `history_config` 的組件均不受影響

- regression-test:
  - 確認其他有 `history_config.range` 的組件（如農藥批發稽查）`AnimatedColumnChart` 仍優先使用 `history_data[0]`
  - 確認 `TimelineSeparateChart` 等其他圖表類型的 series 來源不變（仍為 `chart_data`）

- traceability:
  - N/A

- next-actions:
  - 若未來需要 `history_data` 精細化（多個 range），可為 `food_poisoning_trend` 補設 `history_config`；目前 fallback 已足夠
