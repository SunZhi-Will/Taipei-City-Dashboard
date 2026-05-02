# 一鍵清理重建食安資料 / One-Step Clean Reset for Food Safety

## 2026-05-03 02:40

- objective:
  - 將食安相關資料清至最乾淨狀態並一次重建到位
  - 避免初始化殘留資料造成 dashboard 與 component 對不上
  - 提供可重複執行的一鍵腳本，降低人工操作風險

- files:
  - migrations/reset_food_safety_clean.sh

- summary:
  - 新增 `reset_food_safety_clean.sh`，整合備份、清理、重建、驗證四步驟
  - 腳本會先備份 `dashboardmanager` 關鍵 metadata 表與 `dashboard` 食安資料表到 `/tmp`
  - 清理範圍僅限食安 7 組件、`food_safety_tpe`、`map-layers-*` 相關 metadata，避免影響其他模組
  - 依資料檔型態選擇重建策略：
    - `food_safety_data.sql` 存在時採「先 drop 再 full dump 匯入」
    - 否則改用 `add_food_safety_data_tables.sql` 的 idempotent 路徑
  - metadata 重建前自動校正 `component_maps/components/dashboards` 序列，避免 duplicate key
  - 所有 `psql` 操作均加入 `ON_ERROR_STOP=1`，避免出現假成功

- change-type:
  - Added
  - Fixed

- technical-details:
  - 備份輸出：
    - `/tmp/food_safety_manager_backup_<timestamp>.sql`
    - `/tmp/food_safety_data_backup_<timestamp>.sql`
  - metadata 清理 SQL 包含：`query_charts`, `component_charts`, `component_maps`, `components`, `dashboard_groups`, `dashboards`
  - data 清理 SQL 包含 7 張食安資料表：
    - `food_poisoning_trend`
    - `food_poisoning_cause`
    - `food_poisoning_food`
    - `food_poisoning_place`
    - `ntpc_food_factory`
    - `taipei_imap_food`
    - `wholesale_pesticide_inspection`

- verification:
  - 執行：`./migrations/reset_food_safety_clean.sh`
  - 觀察腳本輸出：全程無 SQL error，最終顯示 `[OK] food safety clean reset completed`
  - API 驗證：`GET /api/v1/dashboard/food_safety_tpe?city=taipei` 回 `200`
  - DB 驗證：`dashboards` 僅保留
    - `food_safety_tpe`
    - `map-layers-taipei`
    - `map-layers-metrotaipei`
  - 資料量驗證：
    - `taipei_imap_food = 13695`
    - `ntpc_food_factory = 1230`
    - `wholesale_pesticide_inspection = 39254`

- performance-impact:
  - 一次性重建作業會有短暫資料不可用窗口
  - 重建完成後查詢效能與先前一致，無新增 runtime 負擔

- impact-risk:
  - 此腳本屬資料破壞性操作（會刪除並重建食安相關資料）
  - 已以 `/tmp` 備份降低回滾風險；仍建議在執行前確認目標環境

- regression-test:
  - 重載前端後，確認食安儀表板 7 組件均正常顯示
  - 驗證 `map-layers-taipei` / `map-layers-metrotaipei` API 不再 404
  - 抽查 `component/:id/chart?city=taipei` 回傳結果非空

- traceability:
  - 相關 migration：`migrations/food_safety_components.sql`
  - 相關 migration：`migrations/add_food_safety_components.sql`
  - 相關修復 log：`user-added/log/2026-05-03/0235-fix-map-layers-dashboard-404.md`

- next-actions:
  - 若需連同地圖圖層內容一起恢復，可再執行 `migrations/add_7_static_map_layers.sql`