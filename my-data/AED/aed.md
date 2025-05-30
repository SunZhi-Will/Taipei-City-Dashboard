# 自動體外心臟去顫器放置地點（index: `aed`）

## 1. `dashboardmanager` 資料庫

### 1.1 插入 `components` 資料表

```sql
INSERT INTO components (
  index, name
)
VALUES (
  'aed',
  '自動體外心臟去顫器'
);
```

### 1.2 插入 `component_charts` 資料表

```sql
INSERT INTO component_charts (
  index, color, types, unit
)
VALUES (
  'aed',
  ARRAY[#fc038c],
  ARRAY['DistrictChart', 'ColumnChart'],
  '處'
)
```

### 1.3 插入 `component_maps` 資料表

```sql
INSERT INTO component_maps (
  index,
  title,
  type,
  source,
  property
) VALUES (
  'aed_map',
  '自動體外心臟去顫器放置地點',
  'circle',
  'geojson',
  '[
    {"key": "name", "name": "場所名稱"},
    {"key": "address", "name": "地址"},
    {"key": "latitude", "name": "緯度"},
    {"key": "longitude", "name": "經度"},
    {"key": "category", "name": "場所分類"},
    {"key": "type", "name": "場所類型"},
    {"key": "location_desc", "name": "AED 放置地點"}
  ]'::json
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
  contributors,
  created_at,
  updated_at,
  query_type,
  query_chart,
  city
)
VALUES (
  'aed',
  'static',
  '衛生局',
  '記錄臺北市公共場所自動體外心臟去顫器（AED）設置資訊與位置分布',
  '本資料集收錄臺北市各公共與半公共場所設置之自動體外心臟去顫器（AED）位置資訊，包含設置單位名稱、地址、聯絡方式、所在行政區、AED 類型與子類型、放置地點描述等欄位。資料來源涵蓋各級政府機關、教育機構、交通樞紐、運動場館、文化設施與大型商業空間等，能夠反映 AED 在城市空間中的部署密度與可近性，具備地理參照與分類資訊，適合用於地圖視覺化與空間分布分析。此資料可配合時間或人口資料，探討急救設施普及程度與潛在缺口，亦可作為政府推動公共健康與災害應變策略之參考依據。',
  '可應用於城市公共安全規劃、緊急醫療可近性分析、AED 覆蓋範圍評估與資源分布不均之偵測。適合支援如「高風險區域 AED 覆蓋率檢查」、「公共建物緊急應變設備盤點」、「學校或體育館急救設施普及程度分析」等場景。也可搭配人口年齡結構、交通熱區或群聚活動資料，進行跨域整合應用，強化防災韌性與公共健康服務佈局，如：推估高齡人口密集區 AED 遮蔽率、分析節慶期間大型活動場域急救設施臨時佈署等。',
  ARRAY['https://data.taipei/dataset/detail?id=cd050577-115f-4299-b37a-012ff490a632'],
  ARRAY['doit'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    district AS x_axis,
    COUNT(*) AS data
  FROM aed_tpe
  GROUP BY district
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY['北投區','士林區','內湖區','南港區','松山區','信義區','中山區','大同區','中正區','萬華區','大安區','文山區'],
    t.x_axis
  );$SQL$,
  'taipei'
);
```

#### 1.4.2 雙北

```sql
INSERT INTO query_charts (
  index,
  time_from,
  source,
  short_desc,
  long_desc,
  use_case,
  links,
  contributors,
  created_at,
  updated_at,
  query_type,
  query_chart,
  city
)
VALUES (
  'aed',
  'static',
  '衛生局',
  '記錄雙北地區公共場所自動體外心臟去顫器（AED）設置資訊與位置分布',
  '本資料集收錄雙北地區各公共與半公共場所設置之自動體外心臟去顫器（AED）位置資訊，包含設置單位名稱、地址、聯絡方式、所在行政區、AED 類型與子類型、放置地點描述等欄位。資料來源涵蓋各級政府機關、教育機構、交通樞紐、運動場館、文化設施與大型商業空間等，能夠反映 AED 在城市空間中的部署密度與可近性，具備地理參照與分類資訊，適合用於地圖視覺化與空間分布分析。此資料可配合時間或人口資料，探討急救設施普及程度與潛在缺口，亦可作為政府推動公共健康與災害應變策略之參考依據。',
  '可應用於城市公共安全規劃、緊急醫療可近性分析、AED 覆蓋範圍評估與資源分布不均之偵測。適合支援如「高風險區域 AED 覆蓋率檢查」、「公共建物緊急應變設備盤點」、「學校或體育館急救設施普及程度分析」等場景。也可搭配人口年齡結構、交通熱區或群聚活動資料，進行跨域整合應用，強化防災韌性與公共健康服務佈局，如：推估高齡人口密集區 AED 遮蔽率、分析節慶期間大型活動場域急救設施臨時佈署等。',
  ARRAY[
    'https://data.taipei/dataset/detail?id=cd050577-115f-4299-b37a-012ff490a632',
    'https://data.ntpc.gov.tw/datasets/61b29f27-219a-4394-9722-af97a5707598'
  ],
  ARRAY['doit','ntpc'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    district AS x_axis,
    COUNT(*) AS data
  FROM (
    SELECT district FROM aed_tpe
    UNION ALL
    SELECT district FROM aed_ntpc
  ) AS combined
  GROUP BY district
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY[
      '北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區',
      '萬華區', '大安區', '文山區', '新莊區', '淡水區', '汐止區', '板橋區', '三重區', '樹林區',
      '土城區', '蘆洲區', '中和區', '永和區', '新店區', '鶯歌區', '三峽區', '瑞芳區', '五股區',
      '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區',
      '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'
    ],
    t.x_axis
  );$SQL$,
  'metrotaipei'
);
```

## 2. `dashboard` 資料庫

### 2.1 `aed_tpe` 資料表

#### Metadata

- 資料來源：台北市資料大平台
- URL：https://data.taipei/dataset/detail?id=cd050577-115f-4299-b37a-012ff490a632
- 資料筆數：2,682
- 更新頻率：每月
- 資料集提供機關：台北市政府衛生局
- 最近更新：2025-05-01 16:57:12
- GeoJSON 檔案：[`aed_tpe.geojson`](./aed_tpe.geojson)

#### 資料轉換

- 原始欄位 → 轉換後欄位
  - `場所名稱` → `name`
  - `地址` → `address`
  - `區域代碼` → `district_code`
  - `緯度` → `latitude`
  - `經度` → `longitude`
  - `場所分類` → `category`
  - `場所類型` → `type`
  - `AED 放置地點` → `location_desc`
- 新增欄位：
  - `district`：行政區名稱，由 `district_code` 映射而來，詳見 [`tranform_aed_tpe.py`](./tranform_aed_tpe.py)

#### 資料庫操作

1. **建立資料表**

```sql
CREATE TABLE aed_tpe (
  name            text,
  address         text,
  district_code   varchar,
  latitude        double precision,
  longitude       double precision,
  category        text,
  type            text,
  location_desc   text,
  district        varchar
);
```

2. **匯入 CSV 檔案**

```bash
docker cp ./aed_tpe.csv postgres-data:/tmp/aed_tpe.csv
```

```sql
COPY aed_tpe (
  name,
  address,
  district_code,
  latitude,
  longitude,
  category,
  type,
  location_desc,
  district
)
FROM '/tmp/aed_tpe.csv'
WITH (
  FORMAT csv,
  HEADER,
  ENCODING 'UTF8'
);
```

3. **資料聚合**（作為 `query_charts` 的 `query_chart`）

```sql
SELECT * FROM (
  SELECT
    district AS x_axis,
    COUNT(*) AS data
  FROM aed_tpe
  GROUP BY district, category
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY['北投區','士林區','內湖區','南港區','松山區','信義區','中山區','大同區','中正區','萬華區','大安區','文山區'],
    t.x_axis
  );
```

> [!NOTE]
> 可考慮將 `category` 作為第二維度，以顯示不同類型的 AED 分布。

### 2.2 `aed_ntpc` 資料表

#### Metadata

- 資料來源：新北市政府開源資料
- URL：
  - https://data.ntpc.gov.tw/datasets/61b29f27-219a-4394-9722-af97a5707598
  - [OpenAI Swagger UI](https://data.ntpc.gov.tw/openapi/swagger-ui/index.html?configUrl=%2Fapi%2Fv1%2Fopenapi%2Fswagger%2Fconfig&urls.primaryName=%E6%96%B0%E5%8C%97%E5%B8%82%E6%94%BF%E5%BA%9C%E8%A1%9B%E7%94%9F%E5%B1%80%28229%29#/CSV/get_61b29f27_219a_4394_9722_af97a5707598_csv)
- 資料筆數：1,733
- 更新頻率：每月
- 資料集提供機關：新北市政府衛生局

> [!NOTE]
> 可執行 Shell 腳本 [`my-data/get_ntpc_data.sh`](../get_ntpc_data.sh) 下載資料

#### 資料轉換

原始欄位有

```
"seqno","organizer","tel","extension","mobile telephone","zipcode","district","hosp_addr","type","location","mon_stime","mon_dtime","tue_stime","tue_dtime","wed_stime","wed_dtime","thu_stime","thu_dtime","fri_stime","fri_dtime","sat_stime","sat_dtime","sun_stime","sun_dtime","remark","date","battery expiration date","electrical pads expiration date"
```

意義為

```
序號、主管機關單位名稱、電話、分機、行動電話、郵遞區號、行政區、地址、場所分類、AED 放置地點、周一起、周一迄、周二起、周二迄、周三起、周三迄、周四起、周四迄、周五起、周五迄、周六起、周六迄、周日起、周日迄、備註：AED 新登錄時間、設置日期、電池使用期限、電擊貼片使用期限
```

經 [`transform_aed_ntpc.py`](./transform_aed_ntpc.py) 轉換後，僅保留以下欄位

- 主管機關單位名稱（`name`）
- 行政區（`district`）
- 地址（`address`）
- 場所分類（`category`）
- AED 放置地點（`location_desc`）

#### 資料庫操作

1. **建立資料表**

```sql
CREATE TABLE aed_ntpc (
  name text,
  district text,
  address text,
  category text,
  location_desc text
);
```

2. **匯入 CSV 檔案**

```bash
docker cp ./aed_ntpc.csv postgres-data:/tmp/aed_ntpc.csv
```

```sql
COPY aed_ntpc (
  name,
  district,
  address,
  category,
  location_desc
)
FROM '/tmp/aed_ntpc.csv'
WITH (
  FORMAT csv,
  HEADER,
  ENCODING 'UTF8'
);
```
