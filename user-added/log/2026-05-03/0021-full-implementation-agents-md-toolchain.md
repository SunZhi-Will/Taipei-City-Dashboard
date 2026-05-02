# 深度實作 AGENTS.md 文件對應的部署工具鏈 / Full Implementation of AGENTS.md Deployment Toolchain

## 2026-05-03 00:21

- objective:
  - 深度分析 AGENTS.md 內容，找出與現有腳本/設定之間的落差，全面補齊實作

- files:
  - migrations/deploy_to_docker.sh
  - migrations/verify_all.sh
  - .vscode/scripts/docker-task.sh
  - .vscode/scripts/docker-task.ps1
  - .vscode/tasks.json
  - Taipei-City-Dashboard-DE/docker/develop/.env.template
  - AGENTS.md

- summary:
  - **deploy_to_docker.sh**：原本只部署 air_station_map_metrotaipei。補齊食安 8 組件所需的 4 個 SQL 遷移步驟（Step 4–7），支援雙資料庫架構（dashboardmanager + dashboard）
  - **verify_all.sh**：原本只驗證 air_station_map。補充食安 8 組件的完整驗證查詢（components 表 + dashboards 表）
  - **docker-task.sh**：`quick-up` 首次偵測與 `bootstrap-full` 均補入 `dashboard-fe-init`（npm ci），確保 FE node_modules 安裝。新增 `airflow-up` action，含 .env 存在性檢查與 port 衝突提示
  - **docker-task.ps1**：同步 docker-task.sh 的 FE init 與 `airflow-up` 修正（涵蓋 Windows Docker Desktop 與 WSL 兩路徑）
  - **tasks.json**：新增 `docker:airflow-up`、`docker:status` 兩個 VS Code Task，讓開發者可直接從命令面板啟動 Airflow 或查看容器狀態
  - **.env.template（DE Airflow）**：首次建立 Airflow compose 的環境變數範本，說明如何透過 host.docker.internal 連接主 stack 的 postgres-manager（port 5433）與 redis
  - **AGENTS.md**：①§3.2 改用 `run --rm` 指令格式（與 docker-task.sh 一致）；②§3.4 新增 Airflow port 衝突警告與 .env.template 使用說明；③§4.2 Airflow URL 補上路徑 `/airflow-sit`；④§7 新增「Airflow 與 FE port 8080 衝突」解法條目

- change-type:
  - Fixed
  - Added

- technical-details:
  - deploy_to_docker.sh 新增 `run_sql_dashboard()` 函數，使用 `PGPASSWORD="${DB_DASHBOARD_PASSWORD}"` 連接 postgres-data 容器
  - PGPASSWORD 明確傳入（而非依賴 PGPASSWORD 環境變數），解決 psql interactive prompt 問題
  - Airflow compose 使用獨立 docker-compose 網路（develop_default），不加入 br_dashboard，因此需透過 host.docker.internal 連接主 stack 服務
  - docker-task.ps1 `Use-WindowsDocker` 的 bootstrap-full 從 `compose -f docker-compose-init.yaml up`（啟動全部服務）改為逐一 `run --rm`，與 bash 版一致，避免 foreground 鎖定

- verification:
  - `bash -n .vscode/scripts/docker-task.sh` — 語法檢查
  - `cat migrations/deploy_to_docker.sh | grep "Step "` — 確認 7 步驟全部列出
  - `cat migrations/verify_all.sh | grep "food_safety_tpe"` — 確認食安儀表板查詢存在
  - `cat .vscode/tasks.json | grep '"label"'` — 確認 5 個 task 全部存在

- impact-risk:
  - `deploy_to_docker.sh` 新增步驟在 `dashboard-be-init-migrations` 容器內執行，若 Step 4–7 SQL 曾執行過（非首次部署），SQL 內的 `CREATE TABLE IF NOT EXISTS` / `INSERT ... ON CONFLICT DO NOTHING` 確保冪等安全
  - `dashboard-fe-init` 在 quick-up 首次偵測區塊加入，不影響已初始化環境（is_db_initialized 為 true 時跳過）
  - `.env.template` 為新增檔案，不影響現有運行環境

- regression-test:
  - 全新環境：刪除 postgres_data volume → 執行 docker:quick-up → 驗證 FE 可啟動、食安 8 組件存在
  - bootstrap-full：執行 docker:bootstrap-full → 確認 FE / BE 均正常運行
  - airflow-up：補填 DE .env → 執行 docker:airflow-up → 確認 http://localhost:8080/airflow-sit/health 回 200

- traceability:
  - 前次 commit: fix: isolate vector-db-upgrade from quick-up; add dashboard_groups for food_safety_tpe
  - 相關 log: user-added/log/2026-05-03/0002-add-agents-md-and-copilot-instructions.md

- next-actions:
  - 若 Airflow 需與 FE 同時運行，修改 `Taipei-City-Dashboard-DE/docker/develop/docker-compose.yaml` 的 webserver ports 為 `"8081:8080"`
  - 將 `airflow_meta` DB 建立步驟納入 bootstrap-full 流程（目前需手動 `docker exec postgres-manager ...`）
  - 考慮在 docker-compose-db.yaml 的 redis 服務加上 `ports: - "6379:6379"` 以支援 Airflow 連接
