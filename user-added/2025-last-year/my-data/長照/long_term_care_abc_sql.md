# 長照 ABC 據點資料（index: `long_term_care_abc`）

## 1. `dashboardmanager` 資料庫

### 1.1 插入 `components` 資料表

```sql
INSERT INTO components (
  index, name
)
VALUES (
  'long_term_care_abc',
  '長照ABC據點'
);
```

### 1.2 插入 `component_charts` 資料表

```sql
INSERT INTO component_charts (
  index, color, types, unit
)
VALUES (
  'long_term_care_abc',
  ARRAY['#4CAF50', '#2196F3', '#9C27B0'],
  ARRAY['DistrictChart', 'PieChart', 'ColumnChart'],
  '處'
);
```

### 1.3 插入 `component_maps` 資料表

```sql
INSERT INTO component_maps (
  index, title, type, source, paint, property
) VALUES (
  'long_term_care_abc_tpe',
  '長照ABC據點',
  'circle',
  'geojson',
  '[{"circle-color": "#4caf50"}]'::json,
  '[
    {"key": "name", "name": "機構名稱"},
    {"key": "address", "name": "機構地址"}
]'::json
);
```

### 1.4 插入 `query_charts` 資料表

#### 1.4.1 台北市

```sql
INSERT INTO query_charts (
  index, time_from, source, short_desc, long_desc, use_case, links, created_at, updated_at, query_type, query_chart,
  city
)
VALUES (
  'long_term_care_abc',
  'static',
  '衛生福利部',
  '台北市長照ABC據點分布與服務項目統計',
  '本資料集收錄台北市長照ABC據點資訊，包含機構名稱、代碼、種類、所在縣市區域、地址、經緯度座標、特約服務項目、聯絡方式等詳細資料。資料涵蓋A級社區整合型服務中心、B級複合型服務中心及C級巷弄長照站等不同層級據點，可分析長照資源在台北市各行政區的分布狀況與服務類型多樣性。適合用於評估長照資源可近性、區域資源均衡性及服務涵蓋率，協助政策制定者優化長照資源配置。',
  '可應用於長照資源盤點與分析、區域資源均衡性評估、長照服務涵蓋率計算、長照據點可及性分析等場景。適合政府單位進行政策規劃、學術研究、社福團體資源整合，以及一般民眾查詢住家附近長照資源。可進一步結合人口老化資料，分析高齡人口與長照資源的空間分布關係。',
  ARRAY['https://data.gov.tw/dataset/152083'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    "township" AS x_axis,
    COUNT(*) AS data
  FROM long_term_care_abc_tpe
  WHERE "county" = '臺北市'
  GROUP BY "township"
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY['北投區','士林區','內湖區','南港區','松山區','信義區','中山區','大同區','中正區','萬華區','大安區','文山區'],
    t.x_axis
  );$SQL$,
  'taipei'
);
```

#### 1.4.2 雙北地區

```sql
INSERT INTO query_charts (
  index, time_from, source, short_desc, long_desc, use_case, links, created_at, updated_at, query_type, query_chart,
  city
)
VALUES (
  'long_term_care_abc',
  'static',
  '衛生福利部',
  '雙北地區長照ABC據點分布與服務項目統計',
  '本資料集收錄雙北地區的長照ABC據點完整資訊，包含機構基本資料、所在位置、服務項目與聯絡方式等。資料涵蓋A級社區整合型服務中心、B級複合型服務中心及C級巷弄長照站等不同層級據點，可分析雙北地區長照資源的空間分布與服務類型多樣性。適合用於跨縣市長照資源比較、區域合作規劃、資源共享機制設計等分析，並可結合人口統計資料進行更深入的區域需求評估。',
  '可應用於雙北生活圈長照資源整合分析、跨縣市資源共享規劃、都會區長照服務網絡建置等場景。適合地方政府進行跨域合作規劃、都會區長照政策制定、學術研究，以及社福團體進行資源整合與服務網絡建構。可進一步結合交通可及性分析，評估長照服務的實際可及範圍。',
  ARRAY['https://data.gov.tw/dataset/152083'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    "township" AS x_axis,
    COUNT(*) AS data
  FROM (
    SELECT "township" FROM long_term_care_abc_tpe
    UNION ALL
    SELECT "township" FROM long_term_care_abc_ntpc
  ) AS combined_tables
  GROUP BY "township"
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY['北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區', '萬華區', '大安區', '文山區', '新莊區', '淡水區', '汐止區', '板橋區', '三重區', '樹林區', '土城區', '蘆洲區', '中和區', '永和區', '新店區', '鶯歌區', '三峽區', '瑞芳區', '五股區', '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區', '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'],
    t.x_axis
  );$SQL$,
  'metrotaipei'
);
```

## 2. 資料表結構

### 2.1 長照 ABC 據點資料表（台北市）

```sql
CREATE TABLE IF NOT EXISTS long_term_care_abc_tpe (
    "name" TEXT NOT NULL, --機構名稱
	"code" TEXT NOT NULL, --機構代碼
	"type" TEXT NOT NULL, --機構種類
	"county" TEXT NOT NULL, --縣市
	"township" TEXT NOT NULL, --區
	"address" TEXT, --地址全址
	"longitude" FLOAT, --經度
	"latitude" FLOAT, --緯度
	"abc_level" TEXT NOT NULL, --O_ABC
	"services" TEXT --特約服務項目
);
```

### 2.2 長照 ABC 據點資料表（新北市）

```sql
CREATE TABLE IF NOT EXISTS long_term_care_abc_ntpc (
    "name" TEXT NOT NULL, --機構名稱
	"code" TEXT NOT NULL, --機構代碼
	"type" TEXT NOT NULL, --機構種類
	"county" TEXT NOT NULL, --縣市
	"township" TEXT NOT NULL, --區
	"address" TEXT, --地址全址
	"longitude" FLOAT, --經度
	"latitude" FLOAT, --緯度
	"abc_level" TEXT NOT NULL, --O_ABC
	"services" TEXT --特約服務項目
);
```

## 3. 資料匯入指令

### 3.1 複製 CSV 檔案到 Docker 容器

```bash
# 複製台北市資料到Docker容器
docker cp ./長照ABC據點_臺北市_處理後.csv postgres-data:/tmp/long_term_care_abc_tpe.csv

# 複製新北市資料到Docker容器
docker cp ./長照ABC據點_新北市_處理後.csv postgres-data:/tmp/long_term_care_abc_ntpc.csv
```

### 3.2 匯入資料到 PostgreSQL

```sql
-- 1. 清空現有資料（如果有的話）
TRUNCATE TABLE long_term_care_abc_tpe;
TRUNCATE TABLE long_term_care_abc_ntpc;

-- 2. 匯入台北市資料
\COPY long_term_care_abc_tpe (
    name,       -- 機構名稱
    code,       -- 機構代碼
    type,       -- 機構種類
    city,       -- 縣市
    district,   -- 區
    address,    -- 地址全址
    lng,        -- 經度
    lat,        -- 緯度
    abc_level,  -- O_ABC
    services    -- 特約服務項目
)
FROM '/tmp/long_term_care_abc_tpe.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8',
    NULL ''
);

-- 3. 匯入新北市資料
\COPY long_term_care_abc_ntpc (
    name,       -- 機構名稱
    code,       -- 機構代碼
    type,       -- 機構種類
    city,       -- 縣市
    district,   -- 區
    address,    -- 地址全址
    lng,        -- 經度
    lat,        -- 緯度
    abc_level,  -- O_ABC
    services    -- 特約服務項目
)
FROM '/tmp/long_term_care_abc_ntpc.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8',
    NULL ''
);
```

## 4. 常用查詢範例

### 4.1 統計各區長照 ABC 據點數量（台北市）

```sql
SELECT
    district,
    COUNT(*) AS count
FROM
    long_term_care_abc_tpe
WHERE
    city = '臺北市'
GROUP BY
    district
ORDER BY
    count DESC;
```

### 4.2 查詢各類長照服務據點數量（新北市）

```sql
SELECT
    type,
    COUNT(*) AS count
FROM
    long_term_care_abc_ntpc
GROUP BY
    type
ORDER BY
    count DESC;
```

### 4.3 查詢提供特定服務的據點（雙北地區）

```sql
-- 查詢提供「居家服務」的據點（台北市）
SELECT
    name,
    district,
    address,
    services
FROM
    long_term_care_abc_tpe
WHERE
    services LIKE '%居家服務%'
ORDER BY
    district, name;

-- 查詢提供「居家服務」的據點（新北市）
SELECT
    name,
    district,
    address,
    services
FROM
    long_term_care_abc_ntpc
WHERE
    services LIKE '%居家服務%'
ORDER BY
    district, name;
```

### 4.4 建立雙北地區合併視圖

```sql
-- 建立雙北地區長照據點合併視圖
CREATE OR REPLACE VIEW long_term_care_abc_metro AS
SELECT
    'tpe' AS city_code,
    id,
    name,
    code,
    type,
    city,
    district,
    address,
    lng,
    lat,
    abc_level,
    services,
    geom
FROM
    long_term_care_abc_tpe
UNION ALL
SELECT
    'ntpc' AS city_code,
    id,
    name,
    code,
    type,
    city,
    district,
    address,
    lng,
    lat,
    abc_level,
    services,
    geom
FROM
    long_term_care_abc_ntpc;

-- 建立空間索引（如果視圖支援）
-- 注意：某些PostgreSQL版本可能需要使用物化視圖才能建立索引
-- CREATE INDEX IF NOT EXISTS long_term_care_abc_metro_geom_idx ON long_term_care_abc_metro USING GIST(geom);
```

### 4.2 查詢各類長照服務據點數量（雙北地區）

```sql
SELECT
    type,
    COUNT(*) AS count
    "O_ABC",
    COUNT(*) AS "據點數量"
FROM
    long_term_care_abc_metro
GROUP BY
    "O_ABC"
ORDER BY
    "據點數量" DESC;
```

### 4.3 查詢特定區域的長照據點（例如：大安區）

```sql
SELECT
    "機構名稱",
    "機構種類",
    "地址全址",
    "機構電話",
    "特約服務項目"
FROM
    long_term_care_abc_metro
WHERE
    "區" = '大安區'
ORDER BY
    "機構種類", "機構名稱";
```

### 4.4 空間查詢：找出特定點位半徑 1 公里內的長照據點

```sql
SELECT
    "機構名稱",
    "機構種類",
    "地址全址",
    "機構電話",
    ST_Distance(
        ST_Transform(geom, 3826),
        ST_Transform(ST_SetSRID(ST_MakePoint(121.5437, 25.0330), 4326), 3826)
    ) AS distance_meters
FROM
    long_term_care_abc_metro
WHERE
    ST_DWithin(
        ST_Transform(geom, 3826),
        ST_Transform(ST_SetSRID(ST_MakePoint(121.5437, 25.0330), 4326), 3826),
        1000  -- 1公里範圍內
    )
ORDER BY
    distance_meters;
```

## 5. 注意事項

1. 資料來源：衛生福利部長照服務資源地理資訊地圖
2. 更新頻率：建議每月更新一次
3. 座標系統：WGS84 (EPSG:4326)
4. 資料授權：政府資料開放授權條款第 1 版
5. 本 SQL 語法適用於 PostgreSQL 12+ 與 PostGIS 3.0+ 環境
6. 匯入資料前請先確認檔案編碼為 UTF-8，以避免中文字元顯示問題
7. 實際使用時請將範例中的路徑 `/path/to/長照ABC據點_雙北地區.csv` 替換為實際檔案路徑
