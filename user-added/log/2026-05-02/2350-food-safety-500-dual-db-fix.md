# 食安 API 500 修正：雙資料庫架構修正 + BarChart 防禦 / Food Safety API 500 Fix: Dual-DB Architecture + BarChart Guard

## 2026-05-02 23:50

- objective:
  - 食品安全儀表板 component 22-25（食品中毒四組 BarChart/AnimatedColumnChart）全部回傳 500
  - BarChart.vue 在 API 500 後崩潰：`Cannot read properties of undefined (reading 'data')`

- files:
  - migrations/add_food_safety_data_tables.sql  （新增：dashboard DB 專用）
  - migrations/add_food_safety_components.sql  （修正：移除建表/插資料區段，改為注解指引）
  - migrations/run_all.sh  （修正：分開 run_sql / run_sql_data，Step 4 拆為 4a+4b）
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarChart.vue  （修正：optional chaining 防崩潰）

- summary:
  - 根本原因：本系統有兩個 PostgreSQL 容器
    - `postgres-manager` → `dashboardmanager`：存放 components/dashboards/query_charts metadata
    - `postgres-data` → `dashboard`：存放 BE 實際查詢的圖表資料
    - 之前的 migration 把 `food_poisoning_*` 四張表建在 `dashboardmanager`，但 BE query_chart 執行時連的是 `dashboard` → relation does not exist → 500
  - 修復：`pg_dump | psql` 把四張表搬到 `postgres-data/dashboard`
  - 建立 `add_food_safety_data_tables.sql`（針對 dashboard DB）作為後續部署依據
  - 清空 `add_food_safety_components.sql` 中的建表/資料段，避免重跑時又建到錯誤 DB
  - BarChart.vue line 110：`props.series[0].data.length` → `props.series?.[0]?.data?.length ?? 0`

- change-type:
  - Fixed

- technical-details:
  - BE componentData.go:214 的 SQL 使用 DB_DASHBOARD 連線（postgres-data:5432/dashboard）
  - 架構確認：`docker exec dashboard-be env | grep DB_` → DB_DASHBOARD_HOST=postgres-data, DB_MANAGER_HOST=postgres-manager
  - 搬移指令：`docker exec postgres-manager pg_dump -U postgres -d dashboardmanager --table=public.food_poisoning_{trend,cause,food,place} | docker exec -i postgres-data psql -U postgres -d dashboard`

- verification:
  - API 驗證（全 200）：
    ```
    curl http://localhost:8080/api/dev/component/22/chart?city=taipei → status=success, rows=10
    curl http://localhost:8080/api/dev/component/23/chart?city=taipei → status=success, rows=10
    curl http://localhost:8080/api/dev/component/24/chart?city=taipei → status=success, rows=8
    curl http://localhost:8080/api/dev/component/25/chart?city=taipei → status=success, rows=6
    ```
  - DB 確認：`docker exec postgres-data psql -U postgres -d dashboard -c "SELECT count(*) FROM food_poisoning_trend;"` → 113 rows

- impact-risk:
  - 只新增資料到 dashboard DB，不修改現有表結構
  - BarChart.vue 改動為純防禦性 optional chaining，不影響正常渲染邏輯

- regression-test:
  - 開啟食品安全儀表板，4 個 BarChart/AnimatedColumnChart widget 應全部正常顯示
  - 確認其他已存在的 BarChart 組件（如長照、交通）不受影響

- traceability:
  - N/A

- next-actions:
  - run_all.bat / run_all.ps1 亦需補 Step 4a（postgres-data）— 優先級低（本機開發用 run_all.sh）
