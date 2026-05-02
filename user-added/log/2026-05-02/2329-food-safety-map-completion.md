# 食安地圖補完：school_kitchen + wholesale + ntpc 修正 / Food Safety Map Completion

## 2026-05-02 23:29

- objective:
  - 4 個食安 GeoJSON 已存在於 `FE/public/mapData/`，但 UI 看不到
  - 根本原因：2 個組件（school_kitchen_imap、wholesale_pesticide_inspection）從未注冊進 DB；ntpc_food_factory 被漏掉 food_safety_tpe dashboard；GeoJSON 是孤立靜態檔

- files:
  - migrations/add_school_kitchen_wholesale_components.sql  （新增）
  - migrations/rollback_school_kitchen_wholesale_components.sql  （新增）
  - migrations/add_food_safety_components.sql  （修正：補上 ntpc_food_factory 至 dashboard ARRAY）
  - migrations/run_all.sh  （新增 Step 5）
  - migrations/run_all.bat  （新增 Step 5）
  - migrations/run_all.ps1  （新增 Step 4+5）

- summary:
  - 診斷發現 4 個 GeoJSON 中只有 taipei_imap_food 完整注冊；ntpc_food_factory 有 DB 條目但被 migration 漏排除於 food_safety_tpe 的 components 陣列；school_kitchen_imap 與 wholesale_pesticide_inspection 完全沒有 DB 對應
  - 即時修正：`UPDATE dashboards SET components = array_append(components, 21)` 修復 ntpc live DB
  - 新增 `add_school_kitchen_wholesale_components.sql`：動態 ID 分配 component_maps(112/113)、components(26/27)、component_charts、query_charts、dashboard 掛載（均幂等）
  - 修正 `add_food_safety_components.sql` 的 INSERT/UPDATE 兩分支均納入 v_ntpc_factory_cid
  - 同步更新三個跨平台 run_all 腳本

- change-type:
  - Fixed
  - Added

- technical-details:
  - school_kitchen_imap：54 筆 Point，properties {name, address, district, result(A1/A2/B1/不符規定), month}；配色與 taipei_imap_food 一致；DonutChart + circle map；city=taipei
  - wholesale_pesticide_inspection：492 筆 Point，4 市場（第一/第二批發/三重/板橋），properties {market, result(合格/不合格), product_name, pesticides, month}；DonutChart 綠/紅；city=metrotaipei
  - 最終 food_safety_tpe.components = {20,22,23,24,25,21,26,27}（8 個組件）
  - dashboard_groups 已確認 taipei(2) + metrotaipei(3) 雙授權

- verification:
  - migration 執行：`docker exec -i postgres-manager psql -U postgres -d dashboardmanager < migrations/add_school_kitchen_wholesale_components.sql` → 全 NOTICE 無 ERROR
  - 幂等測試：二次執行輸出 `already exists`，dashboard components 無重複
  - DB 驗證：
    ```
    SELECT c.id,c.index,cm.id,qc.city,qc.map_config_ids
    FROM components c JOIN component_maps cm ON cm.index=c.index
    JOIN query_charts qc ON qc.index=c.index
    WHERE c.index IN ('school_kitchen_imap','wholesale_pesticide_inspection');
    -- 26 | school_kitchen_imap | 112 | taipei | {112}
    -- 27 | wholesale_pesticide_inspection | 113 | metrotaipei | {113}
    SELECT components FROM dashboards WHERE index='food_safety_tpe';
    -- {20,22,23,24,25,21,26,27}
    ```

- impact-risk:
  - 只新增 rows，不修改現有結構；migration 全 idempotent
  - food_safety_tpe dashboard 新增 2 個 widget，既有組件不受影響
  - ntpc_food_factory 同時出現在 map-layers-metrotaipei 和 food_safety_tpe，兩個 context 均合理

- regression-test:
  - 開啟「食品安全」儀表板，應可見 8 個 widget
  - taipei_imap_food / school_kitchen_imap：DonutChart 月份動畫
  - ntpc_food_factory：MapLegend 圓點靜態地圖
  - wholesale_pesticide_inspection：DonutChart 合格/不合格比例
  - 地圖 layer 切換：4 個 GeoJSON 圓點應正確顯示

- traceability:
  - N/A（無 ticket/PR）

- next-actions:
  - school_kitchen_imap 尚無 DE DAG（目前靜態 GeoJSON），可補建 Airflow DAG
  - wholesale_pesticide_inspection DE DAG 已存在（dags/proj_city_dashboard/wholesale_pesticide_inspection/），可接 Airflow 排程自動更新 GeoJSON
