# 替換 food_safety_components.sql 內容 / Replace food_safety_components.sql Content

## 2026-05-03 01:55

- objective:
  - 移除 food_safety_components.sql 中既有的 INSERT components/component_charts/component_maps 資料
  - 以 food_safety_data.sql 的完整 CREATE TABLE + COPY 內容取代

- files:
  - migrations/food_safety_components.sql

- summary:
  - 執行 `cp food_safety_data.sql food_safety_components.sql`，以資料表結構與完整 COPY 資料覆寫原檔案
  - food_safety_data.sql 與 food_safety_tables.sql 內容完全相同（diff 無差異），合併結果即為其中一份
  - 原檔案內容（INSERT INTO components/component_charts/component_maps 共約 20 行）被移除

- change-type:
  - Changed

- verification:
  - `head -5 migrations/food_safety_components.sql` → 顯示 `-- PostgreSQL database dump`
  - `wc -l migrations/food_safety_components.sql` → 56395（與 food_safety_data.sql 行數一致）
  - `diff food_safety_data.sql food_safety_tables.sql` → 無差異（確認兩附件相同）

- impact-risk:
  - food_safety_components.sql 原本存放組件設定（INSERT components...），若日後需要重新部署組件設定，需自其他 migration 檔案或 food_safety_components 備份中取得
  - 本次修改不影響已執行過的資料庫 migration

- traceability:
  - N/A

- next-actions:
  - 若需保留組件設定，可從 git history 還原原始 food_safety_components.sql 內容
