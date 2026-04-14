# 原住民族人口統計（index: `indigenous_population`）

## 1. `dashboardmanager` 資料庫

### 1.1 插入 `components` 資料表

```sql
INSERT INTO components (
  index, name
) VALUES (
  'indigenous_population',
  '原住民族人口統計'
);
```

### 1.2 插入 `component_charts` 資料表

```sql
INSERT INTO component_charts (
  index, color, types, unit
) VALUES (
  'indigenous_population',
  ARRAY['#4e79a7', '#f28e2b', '#e15759', '#76b7b2', '#59a14f'],
  ARRAY['ColumnChart', 'DonutChart'],
  '人'
);
```

### 1.3 插入 `component_maps` 資料表

```sql
INSERT INTO component_maps (
  index, title, type, source, property, city
) VALUES (
  'indigenous_population_map',
  '原住民族人口分布',
  'fill',
  'geojson',
  '[
    {"key": "district", "name": "行政區"},
    {"key": "population", "name": "人口數"},
    {"key": "indigenous_group", "name": "原住民族群"}
  ]'::json,
  'taipei'
);
```

### 1.4 插入 `query_charts` 資料表

#### 1.4.1 台北市

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
  'indigenous_population',
  'static',
  '原住民族委員會',
  '記錄臺北市原住民族人口統計資料，按行政區、族群、性別及年齡組別分類',
  '本資料集收錄臺北市各行政區原住民族人口統計資料，包含不同原住民族群（如阿美族、泰雅族、排灣族等）之人口數，按性別及年齡組別細分。資料按年度與月份更新，能完整反映原住民族在台北市的人口分布與變動趨勢。此資料可協助了解原住民族群體的人口結構、區域分布特徵，以及不同年齡層與性別的比例，對原住民族政策規劃、文化保存與社會福利資源分配具重要參考價值。',
  '可應用於原住民族人口分析、社會福利政策規劃、教育資源分配等面向。適合支援如「原住民族人口變遷分析」、「原住民族群區域分布比較」、「原住民族年齡結構與性別比例研究」等場景。亦可結合教育、就業、健康等相關指標，進行跨領域分析，例如：探討原住民族教育資源分配、分析原住民族就業狀況與區域經濟發展關聯性，或評估原住民族長照需求與服務供給之空間分布關係。',
  ARRAY['https://www.cip.gov.tw/zh-tw/news/data-list/...'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'three_d',
  $SQL$WITH latest_data AS (
    SELECT
        district,
        indigenous_group,
        SUM(population) as population
    FROM indigenous_population_tpe
    WHERE (year, month) = (
        SELECT year, month
        FROM indigenous_population_tpe
        ORDER BY year DESC, month DESC
        LIMIT 1
    )
    GROUP BY district, indigenous_group
)
SELECT
    district as x_axis,
    indigenous_group as y_axis,
    population as data
FROM latest_data
ORDER BY district, population DESC;$SQL$,
  'taipei'
);
```

#### 1.4.2 雙北整合

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
  'indigenous_population',
  'static',
  '原住民族委員會',
  '記錄雙北地區原住民族人口統計資料，按行政區、族群、性別及年齡組別分類',
  '本資料集收錄雙北地區各行政區原住民族人口統計資料，包含不同原住民族群之人口數，按性別及年齡組別細分。資料按年度與月份更新，能完整反映原住民族在雙北地區的人口分布與變動趨勢。此資料可協助了解原住民族群體的人口結構、區域分布特徵，以及不同年齡層與性別的比例，對原住民族政策規劃、文化保存與社會福利資源分配具重要參考價值。',
  '可應用於原住民族人口分析、社會福利政策規劃、教育資源分配等面向。適合支援如「原住民族人口變遷分析」、「原住民族群區域分布比較」、「原住民族年齡結構與性別比例研究」等場景。亦可結合教育、就業、健康等相關指標，進行跨領域分析，例如：探討原住民族教育資源分配、分析原住民族就業狀況與區域經濟發展關聯性，或評估原住民族長照需求與服務供給之空間分布關係。',
  ARRAY[
    'https://www.cip.gov.tw/zh-tw/news/data-list/...',
    'https://www.ipb.ntpc.gov.tw/...'
  ],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'three_d',
  $SQL$WITH latest_data AS (
    SELECT
        district,
        indigenous_group,
        SUM(population) as population
    FROM (
        SELECT district, indigenous_group, population, year, month
        FROM indigenous_population_tpe
        UNION ALL
        SELECT district, indigenous_group, population, year, month
        FROM indigenous_population_ntpc
    ) combined
    WHERE (year, month) = (
        SELECT year, month
        FROM indigenous_population_tpe
        ORDER BY year DESC, month DESC
        LIMIT 1
    )
    GROUP BY district, indigenous_group
)
SELECT
    district as x_axis,
    indigenous_group as y_axis,
    population as data
FROM latest_data
ORDER BY district, population DESC;$SQL$,
  'metrotaipei'
);
```

## 2. `dashboard` 資料庫

### 2.1 Metadata

- 資料來源：原住民族委員會、台北市政府民政局、新北市政府原住民族行政局
- 更新頻率：每季
- 資料集提供機關：
  - 台北市：台北市政府民政局
  - 新北市：新北市政府原住民族行政局

### 2.2 資料庫操作

1. **建立資料表**

```sql
-- 建立台北市原住民族人口資料表
CREATE TABLE indigenous_population_tpe (
    year integer,
    month integer,
    district text,
    indigenous_group text,
    gender text,
    age_group text,
    population integer
);

-- 建立新北市原住民族人口資料表
CREATE TABLE indigenous_population_ntpc (
    year integer,
    month integer,
    district text,
    indigenous_group text,
    gender text,
    age_group text,
    population integer
);
```

2. **匯入 CSV 檔案**

```bash
# 複製台北市資料
docker cp ./indigenous_population_tpe.csv postgres-data:/tmp/indigenous_population_tpe.csv

# 複製新北市資料
docker cp ./indigenous_population_ntpc.csv postgres-data:/tmp/indigenous_population_ntpc.csv
```

3. **匯入資料**

```sql
-- 匯入台北市資料
COPY indigenous_population_tpe (
    year, month, district, indigenous_group, gender, age_group, population
) FROM '/tmp/indigenous_population_tpe.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 匯入新北市資料
COPY indigenous_population_ntpc (
    year, month, district, indigenous_group, gender, age_group, population
) FROM '/tmp/indigenous_population_ntpc.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

### 2.3 資料探索

1. **基本查詢**

```sql
-- 取得所有資料
SELECT * FROM indigenous_population_tpe
ORDER BY year, month, district, indigenous_group, gender, age_group;
```

2. **時間趨勢分析**

```sql
-- 按年/月統計總人數
SELECT
    year,
    month,
    SUM(population) as total_population
FROM indigenous_population_tpe
GROUP BY year, month
ORDER BY year, month;
```

3. **族群分布**

```sql
-- 各原住民族群人口數
SELECT
    indigenous_group,
    SUM(population) as total_population
FROM indigenous_population_tpe
WHERE (year, month) = (SELECT year, month FROM indigenous_population_tpe ORDER BY year DESC, month DESC LIMIT 1)
GROUP BY indigenous_group
ORDER BY total_population DESC;
```

4. **行政區分布**

```sql
-- 各行政區原住民族人口數
SELECT
    district,
    SUM(population) as total_population
FROM indigenous_population_tpe
WHERE (year, month) = (SELECT year, month FROM indigenous_population_tpe ORDER BY year DESC, month DESC LIMIT 1)
GROUP BY district
ORDER BY total_population DESC;
```

## 3. 資料處理腳本

### 3.1 資料轉換腳本

建立 `transform_indigenous_population.py` 腳本，用於轉換原始資料格式：

```python
import pandas as pd
import os

def transform_taipei(input_file, output_file):
    # 讀取原始資料
    df = pd.read_csv(input_file)

    # 資料轉換邏輯
    # ...

    # 儲存轉換後的資料
    df.to_csv(output_file, index=False, encoding='utf-8')

def transform_new_taipei(input_file, output_file):
    # 讀取原始資料
    df = pd.read_csv(input_file)

    # 資料轉換邏輯
    # ...

    # 儲存轉換後的資料
    df.to_csv(output_file, index=False, encoding='utf-8')

if __name__ == "__main__":
    # 轉換台北市資料
    transform_taipei(
        'by_district_TPE_combined.csv',
        'indigenous_population_tpe.csv'
    )

    # 轉換新北市資料
    transform_new_taipei(
        'by_district_NWT.csv',
        'indigenous_population_ntpc.csv'
    )
```

## 4. 資料更新流程

1. 從資料來源下載最新資料
2. 執行資料轉換腳本
3. 將轉換後的資料匯入資料庫
4. 更新 `query_charts` 中的查詢語句（如有需要）

## 5. 注意事項

1. 資料隱私：確保資料已去識別化，不包含個人識別資訊
2. 資料授權：確認資料來源的授權允許公開使用
3. 資料品質：定期檢查資料完整性與正確性
4. 效能優化：針對大型資料表建立適當的索引

## 6. 參考資源

- 原住民族委員會開放資料平台
- 台北市政府資料開放平台
- 新北市政府資料開放平台
