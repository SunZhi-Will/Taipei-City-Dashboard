# 深度分析食安儀表板截圖並修正三個顯示 Bug / Deep Analysis and Fix of Food Safety Dashboard Display Bugs

## 2026-05-03 00:40

- objective:
  - 深度分析「食安守護」儀表板截圖，識別所有資料錯誤與顯示方式錯誤，全面修復

- files:
  - migrations/fix_food_safety_display_bugs.sql（新增）
  - migrations/rollback_fix_food_safety_display_bugs.sql（新增）
  - migrations/deploy_to_docker.sh（更新 Step 8）
  - Taipei-City-Dashboard-DE/dags/proj_city_dashboard/wholesale_pesticide_inspection/wholesale_pesticide_inspection.py

- summary:
  - **深度分析**：截圖顯示 food_safety_tpe 儀表板（食安守護）有 3 個根本 Bug 導致「資料全錯、顯示全錯」
  - **Bug 1 修正**：`food_poisoning_trend` query_chart SQL 中 x_axis 從 `(year||'-01-01')::timestamptz` 改為 `(year||'-'||LPAD(month,2,'0')||'-01')::timestamptz`，讓 AnimatedColumnChart 能正確按月份播放
  - **Bug 2 修正**：`wholesale_pesticide_inspection` 和 `ntpc_food_factory` 的 `city='metrotaipei'`，但 API 預設 `city='taipei'` → 返回 "No chart data available"。修正：INSERT 新增 `city='taipei'` 行
  - **Bug 3 修正**：DAG `roc_to_date()` 函數中，4 位數西元年（如 `2013`）被錯誤當作民國年（+1911 = 3924）。修正：加入 `y_raw >= 1900` 判斷，直接使用西元年

- change-type:
  - Fixed

- technical-details:
  - **Bug 1 根本原因**：`AnimatedColumnChart.vue` 用 `pt.x?.slice(0,7)` 提取 "YYYY-MM" 作為 animation frame key。舊 SQL 所有月份都有 x="YYYY-01-01"，導致 12 個月全壓縮到 "YYYY-01" frame → 動畫只能播 12 年，不能播月
  - **Bug 2 根本原因**：`GetComponentChartData` controller 中，`query.City` 空時預設 `"taipei"`。`query_charts` 表按 `(index, city)` 存多份設定，`wholesale_pesticide` 和 `ntpc_factory` 只有 `metrotaipei` 行 → JOIN 失敗 → "No chart data available"
  - **Bug 3 根本原因**：PDF 報表偶有西元年格式（如 `2013/12/28`），`roc_to_date("2013/12/28")` → `int("2013")+1911 = 3924` → 無效日期資料入庫 → 前端顯示 "3924年12月"
  - fix_food_safety_display_bugs.sql 含內建 DO $verify$ 驗證區塊，確保三個修正均成功套用
  - deploy_to_docker.sh 新增 Step 8 確保未來全新部署自動執行此修正

- verification:
  - `curl http://localhost:8088/api/v1/component/22/chart` → 02月 series 的 x 值為 "2016-02-01"（非 "2016-01-01"）✓
  - `curl http://localhost:8088/api/v1/component/27/chart` → {"data":[{"data":[{"x":"合格","y":452},{"x":"不合格","y":40}]}],"status":"success"} ✓
  - `curl http://localhost:8088/api/v1/component/21/chart` → map_legend 資料正常返回 ✓
  - SQL migration 輸出三個 NOTICE 確認 ✓

- impact-risk:
  - fix_food_safety_display_bugs.sql 只做 UPDATE（query_chart SQL text）和 INSERT（新增 taipei 城市行），不刪除任何資料
  - `deploy_to_docker.sh` Step 8 為冪等操作（INSERT ... ON CONFLICT DO NOTHING / UPDATE 相同值）
  - roc_to_date() 改動：只影響 4 位數西元年邊界判斷（原邏輯在正常 ROC 年格式下行為不變）

- regression-test:
  - 重新呼叫 `GET /api/v1/component/22/chart` 確認各月份有獨立的 YYYY-MM key
  - 重新呼叫 `GET /api/v1/component/27/chart?city=metrotaipei` 確認 metrotaipei context 仍正常
  - 在 Airflow DAG 環境中插入測試日期 "2013/12/28" 驗證 roc_to_date 返回 datetime(2013,12,28) 而非 3924
  - 執行 rollback SQL 再重新 apply，確認冪等性

- traceability:
  - 相關 log: user-added/log/2026-05-03/0021-full-implementation-agents-md-toolchain.md
  - 前次 commit: fix: isolate vector-db-upgrade from quick-up; add dashboard_groups for food_safety_tpe

- next-actions:
  - 待 Airflow 正式運行後，taipei_imap_food / school_kitchen_imap / wholesale_pesticide_inspection 的 DonutChart 目前仍使用 hardcode ARRAY 數值（452,40 等）。應改為從 dashboard DB 動態查詢 live 表
  - 如需「月趨勢」動畫圖（AnimatedColumnChart）顯示農藥不合格按批發市場分布，應在 wholesale_pesticide_inspection 新增第二組 chart_type + query_chart（query_type=time）
