# 修正 AnimatedColumnChart 使用歷史資料 / Fix AnimatedColumnChart Using History Data

## 2026-05-03 06:11

- objective:
  - 「食品業者衛生稽查地圖」動態長條圖顯示「暫無可播放的月份資料」，無法播放月份動畫

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - `DashboardComponent` 對所有圖表類型統一傳 `:series="config.chart_data"`
  - `chart_data` 來自 `/component/{id}/chart`，回傳二維彙總資料（`x_axis` 為類別標籤，無時間維度）
  - `AnimatedColumnChart` 需要的是 `history_data[0]`（來自 `/component/{id}/history`，格式為 `[{name, data:[{x:"YYYY-MM...", y},...]}]`）
  - 新增 `activeChartSeries` computed：當 `activeChart === 'AnimatedColumnChart'` 時回傳 `props.config.history_data?.[0] ?? null`，其他圖表維持使用 `chart_data`
  - 將 template 內兩處（主圖區、popup 圖區）`:series="config.chart_data"` 改為 `:series="activeChartSeries"`

- change-type:
  - Fixed

- technical-details:
  - 根本原因：`/chart` 端點回傳 `[{data:[{x:"合格",y:12774},...]}]`，`isYearMonth("合格")` 返回 false，導致 `monthlyData.months` 永遠為空
  - `/history` 端點回傳 `[{name:"合格",data:[{x:"2023-05-01T00:00:00+08:00",y:233},...]}]`，`isYearMonth` 可正確辨識
  - `history_config.range` 已設為 `["fiveyear_ago"]`，contentStore 會自動非同步載入 `history_data`
  - 若 `history_data` 尚未載入，`activeChartSeries` 返回 `null`，AnimatedColumnChart 暫時顯示空狀態，資料到位後自動更新（Vite 熱更新）

- verification:
  - `docker exec postgres-data psql -U postgres -d dashboard -c "SELECT COUNT(*), MIN(month), MAX(month) FROM public.taipei_imap_food;"` → 13695 筆，2023-05 ~ 2026-04
  - `curl http://localhost:8088/api/v1/component/45/history?city=taipei&start_time=2021-01-01T00:00:00Z&end_time=2026-12-31T00:00:00Z` → 有回傳多月份時序資料
  - `curl http://localhost:8088/api/v1/component/45/chart?city=taipei` → `[{data:[{x:"合格",...}]}]`，確認無時間維度

- impact-risk:
  - 僅影響 `AnimatedColumnChart` 圖表類型，其他所有圖表類型不受影響
  - 若某組件同時使用 `AnimatedColumnChart` 但未設定 `history_config.range`，則 `history_data` 不會載入，圖表仍顯示空狀態（合理 fallback）

- regression-test:
  - 驗證「食品業者衛生稽查地圖」動態長條圖正常顯示月份動畫
  - 驗證其他圖表類型（DonutChart、BarChart 等）顯示不受影響
  - 切換圖表模式（圓餅圖 ↔ 動態長條圖）確認兩者皆正常

- traceability:
  - N/A

- next-actions:
  - 若未來新增其他需要 history_data 的圖表類型，需同樣更新 `activeChartSeries` computed
