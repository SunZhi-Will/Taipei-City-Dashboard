# PostgreSQL 操作筆記

本篇筆記收錄 PostgreSQL 和 SQL 的相關操作和技巧，適用於城市儀表板專案。

## PostgreSQL

### `psql` Cheatsheet

```pgsql
-- 🏁 資料庫操作
\l                    -- 列出所有資料庫
\c dbname             -- 切換資料庫（connect）

-- 📋 表格操作
\dt                   -- 列出目前資料庫所有資料表
\d table_name         -- 查看指定資料表的欄位結構
\d+ table_name        -- 查看資料表詳細資訊（含儲存大小）

-- 🧪 查詢與測試
SELECT * FROM table_name LIMIT 10;   -- 預覽前幾筆資料
SELECT COUNT(*) FROM table_name;     -- 查看資料筆數

-- ⚙️ Schema 與索引
\dn                   -- 列出所有 schema
\di                   -- 列出所有索引
\df                   -- 列出所有函式
\dv                   -- 列出所有 view（檢視表）

-- 🔑 欄位與主鍵
\du                   -- 列出所有使用者
\dt+                  -- 顯示資料表與儲存大小

-- 📥 匯入與匯出（僅 CLI）
\copy table_name FROM 'file.csv' WITH CSV HEADER ENCODING 'UTF8';  -- 從本機匯入
\copy table_name TO 'output.csv' WITH CSV HEADER;                  -- 匯出到本機 CSV

-- 🚪 退出
\q                    -- 離開 psql CLI
```

### 實用 alias

```bash
alias pgdb='docker exec -it postgres-data psql -U postgres -d dashboard'
alias pgdbm='docker exec -it postgres-data psql -U postgres -d dashboardmanager'
```

### CSV 檔案匯入

#### 方法 1：SQL 指令，伺服器端匯入

1. 用 `docker cp` 把檔案複製到 Docker 容器

   ```bash
   docker cp "/local/path/to/your_file.csv" postgres-data:/tmp/your_file.csv
   ```

   請把 `your_file.csv` 替換成實際的 CSV 檔案名稱。

2. 用 SQL 的 `COPY` 指令匯入。

   ```sql
   COPY your_table (
   your_fields
   )
   FROM '/tmp/your_file.csv'
   WITH (
   FORMAT csv,
   HEADER,
   ENCODING 'UTF8'
   );
   ```

   請把 `your_table` 和 `your_fields` 替換成實際的表名和欄位名稱。

## SQL 模板

### `component_charts` 插入模板

https://tuic.gov.taipei/documentation/back-end/components-db#component_charts
https://tuic.gov.taipei/documentation/front-end/supported-chart-types

```sql
INSERT INTO component_charts (
  index,        -- 主鍵，需唯一
  color,        -- 顏色代碼陣列
  types,        -- 圖表類型陣列
  unit          -- 單位（可為 null）
)
VALUES (
  'your_index_key',
  ARRAY['#color1', '#color2', '#color3'],
  ARRAY['ChartType1', 'ChartType2'],
  '單位'  -- 若無單位則填寫 NULL
);
```

範例

```sql
INSERT INTO component_charts (
  index, color, types, unit
)
VALUES (
  'new_immigrant_map',
  ARRAY['#FFB347', '#FFCC00'],
  ARRAY['MapLegend', 'DistrictChart'],
  '人'
);
```

## `query_charts` 插入模板

```sql


```

## 雙北行政區順序

```
["北投區", "士林區", "內湖區", "南港區", "松山區", "信義區", "中山區", "大同區", "中正區", "萬華區", "大安區", "文山區", "新莊區", "淡水區", "汐止區", "板橋區", "三重區", "樹林區", "土城區", "蘆洲區", "中和區", "永和區", "新店區", "鶯歌區", "三峽區", "瑞芳區", "五股區", "泰山區", "林口區", "深坑區", "石碇區", "坪林區", "三芝區", "石門區", "八里區", "平溪區", "雙溪區", "貢寮區", "金山區", "萬里區", "烏來區"]
```
