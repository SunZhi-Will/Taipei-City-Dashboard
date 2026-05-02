# AnimatedColumnChart 深度修復：年份分組 + 重試邏輯 / AnimatedColumnChart Deep Fix: Year-Frame Grouping + Retry Logic

## 2026-05-03 07:29

- objective:
  - 徹底修復「食品中毒月度統計」顯示「暫無可播放的月份資料」的問題
  - 三個根本原因同時修正：SQL 格式、FE grouping 邏輯、API 重試缺失

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue
  - Taipei-City-Dashboard-FE/src/store/contentStore.js
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue（前次已修）
  - DB: dashboardmanager.query_charts (food_poisoning_trend, 兩筆城市)

- summary:
  - **根本原因 1 — SQL 格式（已修正）**：
    舊 SQL 對所有月份使用 `year || '-01-01'` 作為 x_axis，導致 2 月的資料點也顯示為 `1981-01-01`。
    新 SQL：`(year || '-' || LPAD(month, 2, '0') || '-01')::timestamptz`，每個月有正確的月份日期（如 `1981-02-01`）。
  - **根本原因 2 — FE monthlyData grouping（已修正）**：
    舊邏輯：`pt.x.slice(0, 7)` → `"YYYY-MM"` 作為 frame key，語意不清（為何 02月 的 key 是 `"YYYY-01"`？）。
    新邏輯：`pt.x.slice(0, 4)` → `"YYYY"` 作為 year-frame key，明確表達「一幀 = 一年」。
    每個年份幀包含當年 12 個月份的柱狀資料（01月～12月）。
  - **根本原因 3 — API 重試缺失（已修正）**：
    舊邏輯：chart data 抓取失敗 → `catch` block 設 `chart_data = []`（空陣列為 truthy）→ 圖表顯示但 series 長度為 0 → 顯示「暫無資料」。
    新邏輯：使用 `requestWithRetry`（最多 3 次，間隔 1 秒），失敗後設 `chart_data = null`（觸發錯誤 UI，而非假裝有空資料）。
    同步修正 `updateCurrentDashboardAllChartData` 的相同錯誤處理。
  - **前次修正（DashboardComponent.vue）保留**：
    `activeChartSeries = history_data?.[0] ?? chart_data ?? null`，讓無 history_config 的組件可使用 chart_data 驅動動畫。
  - `formatMonthLabel` 支援純年份 key "YYYY" → "YYYY 年"，也保留 "YYYY-MM" → "YYYY 年 M 月"（供 mapMonthlyData 路徑使用）。

- change-type:
  - Fixed

- technical-details:
  - **SQL 變更**（dashboardmanager.query_charts, index=food_poisoning_trend, 兩筆）：
    ```sql
    -- 舊
    (year::text || '-01-01')::timestamptz AS x_axis
    -- 新
    (year::text || '-' || LPAD(month::text, 2, '0') || '-01')::timestamptz AS x_axis
    ```
  - **monthlyData 變更**（AnimatedColumnChart.vue）：
    ```js
    // 舊：pt.x.slice(0, 7) → "YYYY-MM"（所有月份都是 "YYYY-01"，語意混亂）
    // 新：pt.x.slice(0, 4) → "YYYY"（明確 year-frame grouping）
    byMonth[year][s.name] = (byMonth[year][s.name] ?? 0) + (pt.y ?? 0)  // 支援加總以防重複
    ```
  - **formatMonthLabel 變更**：
    ```js
    if (/^\d{4}$/.test(key)) return `${key} 年`;  // 新增：純年份
    // 原有 YYYY-MM 邏輯保留
    ```
  - **contentStore chart fetch 變更**：
    `http.get(...)` → `this.requestWithRetry(() => http.get(...), { maxAttempts: 3, delayMs: 1000 })`
    失敗時：`chart_data = []` → `chart_data = null`（DashboardComponent 已有 `=== null` 錯誤 UI）

- verification:
  - `curl -s "http://localhost:8088/api/v1/component/47/chart?city=taipei"` 確認：
    - series count = 12（01月～12月）
    - 02月 first x = "1981-02-01"（舊 = "1981-01-01"）✓
    - 01月 first x = "1981-01-01" ✓
  - `pt.x.slice(0,4) = "1981"` → `byMonth["1981"]["01月"] = 1`，`byMonth["1981"]["02月"] = value` 無衝突 ✓
  - months = ["1981", ..., "2025"]（45 frames），`months.length > 0` → 動畫顯示 ✓
  - DB 更新驗證：`SELECT LEFT(query_chart,100) FROM query_charts WHERE index='food_poisoning_trend'` 確認含 `LPAD(month,2,'0') || '-01'`

- impact-risk:
  - AnimatedColumnChart：只影響以 series 為驅動的路徑（food_poisoning_trend）。map-synced 路徑（mapMonthlyData）使用 YYYY-MM key，不受影響。
  - contentStore chart_data = null：DashboardComponent template 已有 `v-else-if="config.chart_data === null"` 顯示錯誤狀態，behavior 改善（從空動畫→明確錯誤 UI）。
  - 其他所有圖表類型（BarChart、DonutChart 等）使用 `config.chart_data` 原路徑，不受影響。

- regression-test:
  - 確認食品中毒月度統計（food_poisoning_trend）點「動態長條圖」後可看到 45 年份幀動畫
  - 確認切換城市（臺北市 ↔ 雙北）後動畫仍正常顯示
  - 確認 taipei_imap_food 的 AnimatedColumnChart（map-synced 路徑）仍可正常播放月份動畫
  - 確認 BE down 時圖表顯示「組件資料異常」（而非空動畫）

- traceability:
  - 承接 user-added/log/2026-05-03/0708-animated-column-chart-series-fallback.md（前次修正）
  - migration SQL 已有正確格式：migrations/food_safety_components.sql L348-353

- next-actions:
  - 考慮限制動畫從 2016 年起（與資料相符的起始年份），濾掉早期年份（1981-2015 是 dashboard DB 的歷史資料，本地 dashboardmanager 的資料則從 2016 開始）
  - 優先級：低（目前顯示 45 年歷史資料也合理）
