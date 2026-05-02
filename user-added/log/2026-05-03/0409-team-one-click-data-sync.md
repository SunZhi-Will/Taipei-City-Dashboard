# 團隊一鍵資料同步流程 / Team One-Click Data Sync Workflow

## 2026-05-03 04:09

- objective:
  - 提供可交付給組員的「一鍵同步」流程，讓食安資料、儀表板配置與向量庫狀態快速對齊
  - 降低手動執行多段指令的失誤風險

- files:
  - .vscode/scripts/team-sync.sh
  - .vscode/tasks.json
  - user-added/docs/team-data-sync.md

- summary:
  - 新增 `team-sync.sh`，整合容器檢查、食安資料重建、metadata 套用、BE 重啟、Qdrant 重建與驗證
  - 新增 VS Code task `sync:team-data`，支援 GUI 一鍵執行
  - 新增使用文件，提供組員操作步驟與注意事項

- change-type:
  - Added
  - Changed

- technical-details:
  - `team-sync.sh` 主要流程：
    - 檢查工具（docker/curl/jq）
    - 若容器未就緒，自動呼叫 `docker-task.sh quick-up`
    - 執行 `migrations/reset_food_safety_clean.sh` 做 deterministic 重建
    - 套用 `migrations/food_safety_components.sql`
    - 重啟 `dashboard-be`，等待 API 就緒
    - 呼叫 `POST /api/v1/qdrant/rebuild`
    - 驗證 `food_safety_taipei`、`food_safety_tpe` 與向量查詢結果
  - 強化向量驗證：
    - 查詢 top-10 並檢查是否包含 `taipei_imap_food`，避免 top-5 偶發排序造成誤判

- verification:
  - 實際執行：`bash .vscode/scripts/team-sync.sh`
  - 結果：
    - Qdrant 重建成功，`data_count=14`
    - `food_safety_taipei` 回傳 6 筆（含 `wholesale_pesticide_inspection_taipei`）
    - `food_safety_tpe` 回傳 7 筆
    - 向量查詢（食品業者衛生稽查地圖）結果含 `taipei_imap_food`

- performance-impact:
  - 一次性同步流程包含資料重建與向量重建，執行時間較一般查詢長
  - 常態使用不受影響，僅在同步時產生額外成本

- impact-risk:
  - 此流程會重建食安資料，不適用於需保留本機自訂食安測試資料的情境
  - 若組員本機容器資源不足，重建時間可能拉長

- regression-test:
  - 由組員在乾淨工作樹與既有環境各跑一次 `sync:team-data`
  - 驗證台北/雙北儀表板筆數與索引一致
  - 驗證 AI 查詢「食品業者衛生稽查地圖」可包含目標組件

- traceability:
  - related log: user-added/log/2026-05-03/0314-ai-retrieval-topic-filter-and-qdrant-refresh.md
  - related log: user-added/log/2026-05-03/0258-taipei-only-wholesale-component.md

- next-actions:
  - 可再新增 `--no-reset` 模式，提供僅 metadata+vector 更新的輕量同步路徑