# 外籍移工統計（index: `migrant_workers`）

## 1. `dashboardmanager` 資料庫

### 1.1 插入 `components` 資料表

```sql
INSERT INTO components (
  index, name
) VALUES (
  'migrant_workers_employed',
  '受聘僱外籍移工統計'
);
```

### 1.2 插入 `component_charts` 資料表

```sql
INSERT INTO component_charts (
  index, color, types, unit
) VALUES (
  'migrant_workers_employed',
  ARRAY['#4e79a7', '#f28e2b'],
  ARRAY['ColumnChart'],
  '人'
);
```

### 1.3 插入 `query_charts` 資料表

#### 1.3.1 台北市

```sql
INSERT INTO query_charts (
  index,
  time_from,
  source,
  short_desc,
  long_desc,
  use_case,
  links,
  created_at,
  updated_at,
  query_type,
  query_chart,
  city
) VALUES (
  'migrant_workers_employed',
  'static',
  '勞動部',
  '記錄臺北市受聘僱外籍移工人數之歷年變化，依工作類別與移工國籍統計',
  '本資料集收錄臺北市各產業與社福類別之外籍移工聘僱人數統計，包含製造業、營建業、農林漁牧業、看護工及家庭幫傭等主要工作類別。資料按年度與月份區分，並依移工國籍（如印尼、菲律賓、泰國、越南等）分類統計，能完整反映外籍移工在台北市的就業分布與變動趨勢。此資料可協助掌握勞動市場結構變化、產業人力需求，以及不同國籍移工的就業偏好，對勞動政策制定與人力資源規劃具重要參考價值。',
'可應用於勞動市場分析、產業人力需求評估、移工政策規劃與社會資源分配等面向。適合支援如「製造業移工需求趨勢分析」、「社福類移工照護人力評估」、「不同國籍移工就業分布比較」等場景。亦可結合產業發展指標、人口結構資料或經濟成長數據，進行跨領域分析，例如：探討移工人數與產業景氣關聯性、評估長照政策對社福移工需求之影響，或分析區域發展與移工就業機會之空間分布關係。'
  ARRAY['https://statdb.mol.gov.tw/statiscla/webMain.aspx?sys=100&kind=10&type=1&funid=wqrymenu2&cparm1=wq64'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'three_d',
  $SQL$WITH latest_month AS (
    SELECT year, month
    FROM migrant_workers_employed_tpe
    ORDER BY year DESC, month DESC
    LIMIT 1
),
latest_data AS (
    SELECT *
    FROM migrant_workers_employed_tpe
    WHERE (year, month) = (SELECT year, month FROM latest_month)
),
pivoted_data AS (
    SELECT
        nationality as name,
        job_type,
        SUM(count) as value
    FROM latest_data
    GROUP BY nationality, job_type
)
SELECT
    job_type as x_axis,
    name as y_axis,
    value as data
FROM pivoted_data
ORDER BY job_type, value DESC;$SQL$,
  'taipei'
);
```

#### 1.3.2 雙北

---

## 2. `dashboard` 資料庫

### 2.1 Metadata

- 資料來源：勞動部勞動統計查詢網
- URL：https://statdb.mol.gov.tw/statiscla/webMain.aspx?sys=100&kind=10&type=1&funid=wqrymenu2&cparm1=wq64
- 資料集提供機關：勞動部

### 2.2 資料庫操作

1. **建立資料表**

```sql
-- 建立台北市受聘僱移工資料表
CREATE TABLE migrant_workers_employed_tpe (
    year integer,
    month integer,
    nationality text,
    job_type text,
    count integer
);

-- 建立新北市受聘僱移工資料表
CREATE TABLE migrant_workers_employed_ntpc (
    year integer,
    month integer,
    nationality text,
    job_type text,
    count integer
);
```

2. **匯入 CSV 檔案**

```bash
# 複製台北市資料
docker cp ./migrant_workers_employed_tpe.csv postgres-data:/tmp/migrant_workers_employed_tpe.csv

# 複製新北市資料
docker cp ./migrant_workers_employed_ntpc.csv postgres-data:/tmp/migrant_workers_employed_ntpc.csv
```

3. **匯入資料**

```sql
-- 匯入台北市資料
COPY migrant_workers_employed_tpe (
    year,
    month,
    nationality,
    job_type,
    count
)
FROM '/tmp/migrant_workers_employed_tpe.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8'
);

-- 匯入新北市資料
COPY migrant_workers_employed_ntpc (
    year,
    month,
    nationality,
    job_type,
    count
)
FROM '/tmp/migrant_workers_employed_ntpc.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8'
);
```

### 2.3 資料探索

1. 基本查詢 - 取得所有資料

```sql
SELECT * FROM migrant_workers_employed_tpe
ORDER BY year, month, nationality, job_type;
```

2. 時間趨勢分析 - 按年/月統計總人數

```sql
SELECT
    year,
    month,
    SUM(count) as total_workers
FROM migrant_workers_employed_tpe
GROUP BY year, month
ORDER BY year, month;
```

3. 最新月份資料快照

```sql
WITH latest_month AS (
    SELECT year, month
    FROM migrant_workers_employed_tpe
    ORDER BY year DESC, month DESC
    LIMIT 1
)
SELECT
    m.job_type,
    m.nationality,
    m.count as worker_count
FROM migrant_workers_employed_tpe m
JOIN latest_month lm ON m.year = lm.year AND m.month = lm.month
ORDER BY m.job_type, m.nationality;
```

4. 2022/2023 年度比較分析

```sql
WITH yearly_data AS (
    SELECT
        year,
        job_type,
        SUM(count) as total_workers
    FROM migrant_workers_employed_tpe
    GROUP BY year, job_type
)
SELECT
    job_type,
    MAX(CASE WHEN year = 2023 THEN total_workers END) as y2023,
    MAX(CASE WHEN year = 2022 THEN total_workers END) as y2022,
    ROUND(
        (MAX(CASE WHEN year = 2023 THEN total_workers ELSE 0 END)::numeric /
         NULLIF(MAX(CASE WHEN year = 2022 THEN total_workers ELSE 0 END), 0) - 1) * 100,
        1
    ) as yoy_change_percent
FROM yearly_data
GROUP BY job_type
ORDER BY y2023 DESC NULLS LAST;
```

5. 國籍結構分析（最新月份）

```sql
WITH latest_month AS (
    SELECT year, month
    FROM migrant_workers_employed_tpe
    ORDER BY year DESC, month DESC
    LIMIT 1
)
SELECT
    nationality,
    SUM(count) as worker_count,
    ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (), 1) as percentage
FROM migrant_workers_employed_tpe m
JOIN latest_month lm ON m.year = lm.year AND m.month = lm.month
GROUP BY nationality
ORDER BY worker_count DESC;
```

6. 工作類型趨勢（年度）

```sql
SELECT
    job_type,
    year,
    SUM(count) as annual_workers,
    LAG(SUM(count)) OVER (PARTITION BY job_type ORDER BY year) as prev_year,
    ROUND(
        (SUM(count) - LAG(SUM(count)) OVER (PARTITION BY job_type ORDER BY year)) * 100.0 /
        NULLIF(LAG(SUM(count)) OVER (PARTITION BY job_type ORDER BY year), 0),
        1
    ) as yoy_change_percent
FROM migrant_workers_employed_tpe
GROUP BY job_type, year
ORDER BY job_type, year;
```

7. 熱力圖分析（標準化數據）

```sql
WITH latest_data AS (
    SELECT * FROM migrant_workers_employed_tpe
    WHERE (year, month) = (SELECT year, month FROM migrant_workers_employed_tpe ORDER BY year DESC, month DESC LIMIT 1)
),
job_totals AS (
    SELECT
        job_type,
        SUM(count) as total
    FROM latest_data
    GROUP BY job_type
)
SELECT
    d.job_type,
    d.nationality,
    d.count as worker_count,
    ROUND(d.count * 100.0 / t.total, 1) as percentage_of_job
FROM latest_data d
JOIN job_totals t ON d.job_type = t.job_type
ORDER BY d.job_type, d.count DESC;
```
