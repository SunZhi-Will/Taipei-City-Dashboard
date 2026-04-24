# 強化初始化空品資料匯入流程 / Harden Air Quality Import During Initialization

## 2026-04-24 14:43

- objective:
  - 確保新成員首次初始化（F5 quick-up / bootstrap-full）時，空品資料與組件 metadata 可自動匯入。
  - 消除初始化流程中 migration 容器缺少執行腳本造成的中斷風險。

- files:
  - docker/docker-compose-init.yaml
  - migrations/deploy_to_docker.sh
  - .vscode/scripts/docker-task.ps1

- summary:
  - 新增 `migrations/deploy_to_docker.sh`，集中執行空品初始化 SQL（manager + dashboard 兩個 DB）。
  - 修正 `docker-compose-init.yaml` 的 migration 服務設定：補齊 dashboard DB 環境變數，並改用 `sh ./deploy_to_docker.sh` 執行。
  - 修正 `.vscode/scripts/docker-task.ps1` 的 WSL 初始化流程，在首次與完整初始化中加入 `dashboard-be-init-migrations`。

- change-type:
  - Fixed

- technical-details:
  - `deploy_to_docker.sh` 會依序執行：
  - `01_deploy_air_quality_metadata.sql`（dashboardmanager）
  - `attach_to_dashboard_air_station_map.sql`（dashboardmanager）
  - `02_deploy_air_quality_data.sql`（dashboard）
  - 腳本加上必要環境變數檢查與 SQL 檔存在檢查，且使用 `psql -v ON_ERROR_STOP=1`。
  - 為避免 Alpine `/bin/sh` 不支援間接展開，`require_var` 採 `eval` 取值，確保 POSIX 相容。
  - `docker-compose-init.yaml` 為 migration 容器新增：
  - `DB_DASHBOARD_HOST`
  - `DB_DASHBOARD_USER`
  - `DB_DASHBOARD_PASSWORD`
  - `DB_DASHBOARD_DBNAME`
  - `DB_DASHBOARD_PORT`
  - `.vscode/scripts/docker-task.ps1` 在 WSL 分支中新增：
  - quick-up 首次初始化：`run --rm dashboard-be-init-migrations`
  - bootstrap-full：`run --rm dashboard-be-init-migrations`

- verification:
  - `sh -n migrations/deploy_to_docker.sh`（WSL）→ OK
  - VS Code 診斷：
  - `docker/docker-compose-init.yaml` → No errors found
  - `migrations/deploy_to_docker.sh` → No errors found
  - `.vscode/scripts/docker-task.ps1` → No errors found

- performance-impact:
  - 首次初始化與完整 bootstrap 會多執行一個 migration 容器，時間略增（通常數秒至十餘秒）。
  - 一般非首次 quick-up 路徑不受影響。

- impact-risk:
  - 若 `.env` 未提供 dashboard/manager DB 密碼，migration 腳本會明確失敗並回報缺值，避免靜默不一致。
  - 若後續調整 SQL 檔命名，需要同步更新 `deploy_to_docker.sh` 的清單。

- regression-test:
  - 新環境刪除 volume 後執行 F5 quick-up，確認空品組件可直接顯示（含資料、非 NaN）。
  - 執行 F5 bootstrap-full，確認 migration 與服務啟動全流程成功。
  - 驗證 `map-layers-metrotaipei` 已掛載 `air_station_map_metrotaipei`。

- traceability:
  - N/A

- next-actions:
  - P1: 將 `.vscode/scripts/docker-task.sh` 也改為與 PowerShell 一致的初始化順序（manager → dashboard → migrations）以減少跨平台差異。
