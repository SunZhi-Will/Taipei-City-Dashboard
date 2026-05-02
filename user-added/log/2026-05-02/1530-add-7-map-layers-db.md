# 新增 7 個靜態 GeoJSON 地圖組件全面實作 / Full Implementation of 7 Static GeoJSON Map Layers

## 2026-05-02 15:30

- objective:
  - 讓 7 個新增 GeoJSON 檔案完整顯示於前端儀表板地圖
  - 建立 DB 所需的 components、component_maps、component_charts、query_charts 設定
  - 掛載至既有的 map-layers-taipei / map-layers-metrotaipei 儀表板

- files:
  - migrations/add_7_static_map_layers.sql (新增)
  - migrations/rollback_7_static_map_layers.sql (新增)

- summary:
  - 分析現有 DB schema（dashboardmanager-demo.sql、air_station_map_metrotaipei.sql）確認完整流程
  - 讀取 7 個新 GeoJSON 的幾何類型與屬性欄位，設計對應 paint 表達式
  - 撰寫 idempotent SQL migration（DO $mig$ ... END $mig$），一次建立 7 個組件的全部設定
  - 執行成功：7 rows in query_charts, map-layers-taipei={217,1,2,4,6}, map-layers-metrotaipei={217,219,3,5,7}
  - 新增 rollback 腳本供必要時還原

- change-type:
  - Added

- technical-details:
  - 每個組件的 DB 欄位：
    - components (index, name) → 7 筆
    - component_maps (type='circle', source='geojson', paint JSON 含 match/step 表達式) → 7 筆 (id 103-109)
    - component_charts (color 陣列對應圖例順序, types='{MapLegend}') → 7 筆
    - query_charts (query_type='map_legend', query_chart=SELECT unnest legend SQL, map_config_ids 指向 component_maps.id) → 7 筆
  - paint 設計：
    - air_station_map_taipei: step 表達式依 aqi 值 6 級色階（#00e400 → #7e0023）
    - labor_services_*: match 表達式依 category_label（庇護工場#FF7043、就業服務#26A69A、勞動行政#42A5F5、勞工權益保障#AB47BC、職業訓練#FFA726）
    - museums_*: match 表達式依 type（歷史與人文#E67E22、綜合與其他#7F8C8D、自然與科學#27AE60、藝術與工藝#9B59B6）
    - shelters_*: 單色 #3498DB
  - component IDs 分配：由於 components 表 sequence 從低位開始，7 個新組件取得 id 1-7（無衝突，既有組件 ≥60）
  - component_maps IDs：由 COALESCE(MAX(id),100)+1 分配，取得 103-109

- verification:
  - 執行 `docker exec -i postgres-manager psql -U postgres -d dashboardmanager -f /dev/stdin < migrations/add_7_static_map_layers.sql` 成功
  - 驗證查詢輸出 7 rows，欄位 city/map_config_ids/map_type/source 全部正確
  - dashboards 驗證：map-layers-taipei num_components=5, map-layers-metrotaipei num_components=5

- impact-risk:
  - 影響範圍：dashboardmanager DB 的 4 張表 + 2 個既有 dashboards 的 components 陣列
  - 風險：低；migration 為 idempotent（重複執行先 DELETE 再 INSERT），不影響其他組件
  - 若需還原，執行 `rollback_7_static_map_layers.sql`

- regression-test:
  - 在 http://localhost:8080 開啟「圖資資訊」儀表板（台北 / 雙北）
  - 確認地圖出現新圖層圓點（勞工服務、博物館、避難所、空品測站）
  - 點擊圓點確認彈窗顯示正確欄位
  - 切換台北 / 雙北模式確認 taipei / metrotaipei 版本各自顯示

- traceability:
  - 關聯 log: user-added/log/2026-05-02/1500-import-mapdata-geojson.md
  - N/A (no PR/ticket)

- next-actions:
  - 若資料需定期更新，需建立對應的 Airflow DAG 或排程腳本（目前為靜態 GeoJSON）
  - 優先級：低（視需求再追加）
