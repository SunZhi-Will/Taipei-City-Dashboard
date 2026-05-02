# macOS migration 執行流程補齊 / macOS Migration Runner Alignment

## 2026-05-03 02:27

- objective:
  - 補齊 macOS 使用者可直接執行的 migration 流程
  - 讓 run_all 腳本與食安雙資料庫拆分後的實際執行順序一致
  - 避免 Windows 與 macOS 腳本對食安 migration 的步驟描述與執行結果不一致

- files:
  - migrations/run_all.ps1
  - migrations/run_all.bat
  - migrations/add_food_safety_data_tables.sql
  - migrations/add_school_kitchen_wholesale_components.sql
  - migrations/run_all.sh

- summary:
  - 將 Windows PowerShell 與 cmd 的 run_all 腳本改為明確區分 manager DB 與 dashboard DB
  - 補齊食安資料表建立步驟，先執行 add_food_safety_data_tables.sql，再執行 add_food_safety_components.sql 與 add_school_kitchen_wholesale_components.sql
  - 確認 macOS 的 run_all.sh 可作為實際使用入口，對齊雙 DB 部署流程

- change-type:
  - Fixed
  - Changed

- technical-details:
  - run_all.ps1 新增 manager/data 容器與資料庫變數，Run-Sql 改為接受 container/database 參數
  - run_all.bat 新增 MANAGER_CONTAINER、DATA_CONTAINER、MANAGER_DATABASE、DATA_DATABASE，並補上 Step 4/5/6
  - add_food_safety_data_tables.sql 作為 postgres-data/dashboard 的資料表與 mock 資料來源
  - add_school_kitchen_wholesale_components.sql 作為 school_kitchen_imap 與 wholesale_pesticide_inspection 的 metadata 補完腳本

- verification:
  - `./.vscode/scripts/docker-task.sh status` 可於 macOS 正常執行並列出容器狀態
  - `bash -n migrations/run_all.sh` 通過，shell 腳本可被解析
  - 編輯器診斷：migrations/run_all.ps1 無錯誤、migrations/run_all.bat 無錯誤

- performance-impact:
  - 無直接效能影響
  - 僅修正 migration 執行順序與跨平台工具鏈一致性

- impact-risk:
  - 若使用者只執行 metadata migration、不執行 data tables migration，食安圖表仍可能缺資料
  - 本次修正降低此風險，但仍需確保 postgres-data / postgres-manager 容器名稱符合預設值

- regression-test:
  - 在 macOS 以 `cd migrations && ./run_all.sh` 驗證可依序執行所有步驟
  - 在 Windows 以 PowerShell 執行 `./run_all.ps1` 驗證 Step 4/5/6 順序正確
  - 驗證 food_safety_tpe dashboard 與 school_kitchen_imap / wholesale_pesticide_inspection 組件均可出現

- traceability:
  - 相關 migration：migrations/add_food_safety_components.sql
  - 相關 migration：migrations/food_safety_components.sql

- next-actions:
  - 可再補一份 README 或 DOCKER_QUICK_START 片段，將 macOS migration 執行指令寫成使用者導向版本