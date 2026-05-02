# 食安地圖圖表資料全為 0 的修正 / Fix: Food Safety Map Chart Data All Zero

## 2026-05-02 23:45

- objective:
  - 食安儀表板 4 個地圖型組件（taipei_imap_food/school_kitchen_imap/wholesale_pesticide_inspection/ntpc_food_factory）的 DonutChart 與 MapLegend 全部顯示 0 或無意義預設值
  - taipei_imap_food 地圖中 A3 級 689 筆標點顯示為紅色（不合格色），應為橘色（正在複查）

- files:
  - migrations/fix_food_safety_chart_data.sql  （新增）
  - migrations/rollback_fix_food_safety_chart_data.sql  （新增）

- summary:
  - 根本原因：`query_charts.query_chart` 欄位在開發時使用佔位 SQL：`ARRAY[0,0,0]`，從未更新為真實統計數值
  - 修正方式：直接統計 GeoJSON 檔案中各 result 分類數量，更新 query_chart 為真實計數
  - 同步修正 taipei_imap_food 地圖 paint：補上 `A3 → #FF9800（橘）`，使地圖色彩與 DonutChart 分類一致

- change-type:
  - Fixed

- technical-details:
  - GeoJSON 統計來源（Python json + Counter）：
    - taipei_imap_food.geojson：A1=6774, A2=6000, A3=689, B1=216, B2=15 → 合格=12774, 正在複查=689, 不合格=231
    - school_kitchen_imap.geojson：A1=40, A2=12, B1=1, A3=1（A3 落 else/紅 → 計入不符規定）
    - wholesale_pesticide_inspection.geojson：合格=452, 不合格=40
    - ntpc_food_factory.geojson：1230 筆
  - ntpc_food_factory：query_chart 原無 `value` 欄位 → API 回傳 `value: 0`；補上 `1230 AS value` 後正常
  - taipei_imap_food paint 修正：`"A1","#4CAF50","A2","#8BC34A","A3","#FF9800","#F44336"` — A3 明確對應橘色，B1/B2 落 else=紅色
  - paint 修正後 B1(216筆) 從橘色改為紅色，與 DonutChart「不合格」紅色分類一致

- verification:
  - API 驗證（全部 status=success，數值正確）：
    ```
    GET /component/20/chart?city=taipei
      → 合格=12774, 正在複查=689, 不合格=231
    GET /component/26/chart?city=taipei
      → A1優良=40, A2合格=12, B1限改=1, 不符規定=1
    GET /component/27/chart?city=metrotaipei
      → 合格=452, 不合格=40
    GET /component/21/chart?city=metrotaipei
      → value=1230
    ```

- impact-risk:
  - 僅修改 query_charts.query_chart 欄位（SQL 字串），不影響表結構
  - taipei_imap_food paint 修正：B1(216筆) 地圖顏色由橘轉紅，視覺有輕微變化，但語義更準確
  - school_kitchen/wholesale/ntpc 無 paint 變動

- regression-test:
  - 開啟食品安全儀表板，確認 4 個地圖組件 DonutChart 顯示非零數值
  - 確認 ntpc_food_factory 圖例顯示「1230」
  - 確認 taipei_imap_food 地圖 A3 標點為橘色、B1 標點為紅色

- traceability:
  - 延續同日 2329 log（food-safety-map-completion）與 2350 log（500 dual-db fix）

- next-actions:
  - 當 Airflow DAG 上線後，需改為從 DB 動態查詢計數，而非靜態 hardcode
