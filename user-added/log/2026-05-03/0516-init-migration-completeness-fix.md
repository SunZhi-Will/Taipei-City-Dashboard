# 初始化遷移完整性修復 / Init Migration Completeness Fix

## 2026-05-03 05:16

- objective:
  - 確保 `docker-compose-init.yaml` 的 `dashboard-be-init-migrations` 能完整執行所有必要 migration
  - 修正 init 過程中會中斷或遺漏的食安 migration 步驟

- files:
  - migrations/deploy_to_docker.sh
  - migrations/add_food_safety_data_tables.sql
  - migrations/run_all.sh
  - migrations/run_all.ps1
  - migrations/run_all.bat

- summary:
  - 將 Docker init 的 migration 入口補上 `fix_food_safety_zero_chart_queries.sql`，讓 init 後的食安圖表查詢狀態與手動修復後一致
  - 為 `psql` 執行統一加上 `ON_ERROR_STOP=1`，避免 SQL 失敗時腳本繼續跑造成「看似完成、實際不完整」的遷移結果
  - 修正 `add_food_safety_data_tables.sql` 對舊環境的相容性：補齊 `food_poisoning_*` 系列表的唯一索引，使 `ON CONFLICT` 在既有資料庫上可正常執行
  - 同步更新 `run_all.sh`、`run_all.ps1`、`run_all.bat`，避免手動 migration 與 Docker init 結果分歧

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `deploy_to_docker.sh`
    - `run_sql` / `run_sql_dashboard` 改為 `psql -v ON_ERROR_STOP=1`
    - 新增 Step 8：執行 `fix_food_safety_zero_chart_queries.sql`
  - `add_food_safety_data_tables.sql`
    - 針對舊版已存在但缺少唯一約束的四張表補上唯一索引：
      - `food_poisoning_trend (year, month)`
      - `food_poisoning_cause (year, cause)`
      - `food_poisoning_food (year, food_type)`
      - `food_poisoning_place (year, place)`
    - 讓後續 `ON CONFLICT` 可在歷史 schema 上正常工作，不再於 Step 4 中止
  - `run_all.*`
    - 同步補上 `ON_ERROR_STOP=1`
    - 同步納入 `fix_food_safety_zero_chart_queries.sql`

- verification:
  - 實際重跑 init migration 容器：
    - `cd docker && docker compose -f docker-compose-init.yaml run --rm dashboard-be-init-migrations`
    - 結果：成功執行至 `Step 8：修正食安圖表 0 值查詢` 並輸出 `✅ [Docker] 全部遷移完成！`
  - shell 語法檢查：
    - `bash -n migrations/deploy_to_docker.sh && bash -n migrations/run_all.sh`
    - 結果：無輸出、exit code 0
  - VS Code diagnostics：
    - `migrations/deploy_to_docker.sh` → No errors found
    - `migrations/add_food_safety_data_tables.sql` → No errors found
    - `migrations/run_all.sh` → No errors found
    - `migrations/run_all.ps1` → No errors found
    - `migrations/run_all.bat` → No errors found

- performance-impact:
  - 新增唯一索引會在資料表初始化時多一次索引建立檢查，但屬一次性 migration 成本
  - `ON_ERROR_STOP=1` 不影響查詢效能，只改善失敗回報與部署可靠性

- impact-risk:
  - 若舊環境四張 `food_poisoning_*` 表已存在重複 `(year, key)` 資料，建立唯一索引會失敗並中止 migration；此行為屬預期，因為重複資料本身代表資料品質問題
  - 本次不改動既有資料內容，只補齊索引與遷移步驟，風險集中在初始化/重跑 migration 流程

- regression-test:
  - 執行 `docker compose -f docker/docker-compose-init.yaml run --rm dashboard-be-init-migrations` 應完整成功
  - 首次部署執行 `docker:quick-up` 或 `docker:bootstrap-full` 時，不應再卡在 food safety data tables 的 `ON CONFLICT` 錯誤
  - 手動執行 `migrations/run_all.sh`、`run_all.ps1`、`run_all.bat` 應包含 food safety zero chart 修復步驟

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0512-food-safety-zero-chart-query-fix.md

- next-actions:
  - 可再清理 `docker/docker-compose-init.yaml` 中已過時的 `version` 欄位警告
  - 若要更強的 init 健壯性，可在 `.vscode/scripts/docker-task.sh` 將 DB readiness 由固定 sleep 改為健康檢查輪詢
