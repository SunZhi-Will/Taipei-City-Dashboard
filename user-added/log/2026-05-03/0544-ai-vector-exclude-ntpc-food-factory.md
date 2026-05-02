# AI 向量檢索排除新北食品工廠 / Exclude NTPC Food Factory From AI Vector Retrieval

## 2026-05-03 05:44

- objective:
  - 修正 AI Studio 助手查詢「食品業者衛生稽查地圖」時，仍推薦已從 food_safety_tpe 移除的「新北市食品工廠清冊」
  - 同步更新向量重建來源，避免 Qdrant 重建後再次收錄過期組件

- files:
  - Taipei-City-Dashboard-BE/app/models/componentConfig.go
  - docker/qdrant-upgrade/upgrade_vector_db.py

- summary:
  - 在後端 AI 檢索模型層加入 `ntpc_food_factory` 排除規則，讓向量檢索與 AI tool 結果都不再回傳該組件
  - 在 Qdrant Python 升級腳本的 SQL 中同步排除 `ntpc_food_factory`，避免未來手動重建 collection 時又把舊組件放回去
  - 實際重建 `dashboard-be` 與 `POST /api/v1/qdrant/rebuild`，讓修正立即生效

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 根因確認：
    - `ntpc_food_factory` 雖已自 `food_safety_tpe` 移除，但仍存在 `map-layers-metrotaipei` 這個公開 dashboard
    - 既有 Qdrant 重建資料源抓的是「所有公開 dashboard 的 components」，因此該組件仍會被編入 collection
    - 既有 food safety domain 過濾僅做主題詞命中，不會將 `ntpc_food_factory` 視為已淘汰組件
  - `componentConfig.go`：
    - 新增 `aiSearchExcludedIndexes`
    - 新增 `isAIExcludedIndex(index string)`
    - `GetPublicComponentsForQdrant()` 加入 `qc.index NOT IN ('ntpc_food_factory')`
    - `GetComponentByQueryVectorRich()` 在組裝 rich results 前先排除 `ntpc_food_factory`
  - `upgrade_vector_db.py`：
    - SQL 查詢末尾加上 `and qc.index <> 'ntpc_food_factory'`
    - 確保 Python 路徑的 collection rebuild 與 Go API rebuild 規則一致

- verification:
  - backend 語法檢查：
    - `get_errors` 檢查 `Taipei-City-Dashboard-BE/app/models/componentConfig.go` → `No errors found`
    - `get_errors` 檢查 `docker/qdrant-upgrade/upgrade_vector_db.py` → `No errors found`
  - backend 重建：
    - `docker compose -f docker/docker-compose.yaml up -d --build dashboard-be`
    - 結果：`dashboard-be` rebuilt and running
  - 向量資料庫重建：
    - `curl -sf -X POST 'http://localhost:8088/api/v1/qdrant/rebuild' | jq '{status,message,data_count:(.data|length)}'`
    - 結果：`status=success`, `data_count=14`
  - 向量檢索驗證：
    - `curl -s -X POST 'http://localhost:8088/api/v1/vector/component' -H 'Content-Type: application/x-www-form-urlencoded' --data 'query=食品業者衛生稽查地圖&limit=10&score=0.78' | jq '.data | map({index,name,city,score})'`
    - 結果第一名為 `taipei_imap_food`，返回清單不含 `ntpc_food_factory`
  - dashboard 狀態驗證：
    - `curl -s 'http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=metrotaipei' | jq '.data | map(.index)'`
    - 結果不含 `ntpc_food_factory`
  - 根因邊界驗證：
    - `SELECT COUNT(*) ... WHERE qc.index = 'ntpc_food_factory';`
    - 結果仍為 `2`，證明該組件仍存在其他公開 dashboard，因此必須在 AI/Qdrant 層額外排除

- performance-impact:
  - 檢索時新增一次常數級 index 排除判斷，成本可忽略
  - Qdrant 重建資料量略減，對重建時間有微幅正向效果

- impact-risk:
  - 本次是 AI 與向量索引層排除，不會刪除 `ntpc_food_factory` 的 metadata、本體資料或其他 dashboard 掛載
  - 若未來要讓 `ntpc_food_factory` 再次成為 AI 可推薦組件，需同步移除 Go 與 Python 兩側排除規則

- regression-test:
  - 在 AI Studio 再次詢問「食品業者衛生稽查地圖」，確認推薦清單不再出現「新北市食品工廠清冊」
  - 查詢「新北市食品工廠」相關語句，確認系統不會再將它作為公開 AI 推薦組件
  - 重跑 `POST /api/v1/qdrant/rebuild` 後再次查詢，確認排除規則持續生效

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0521-food-safety-chart-toggle-and-dashboard-trim.md
    - user-added/log/2026-05-03/0541-food-safety-trend-line-and-map-time-animation.md

- next-actions:
  - 若要完全消除後續維護歧義，可再決定是否從 `map-layers-metrotaipei` 也移除 `ntpc_food_factory`，讓公開 dashboard 與 AI 索引來源完全一致
