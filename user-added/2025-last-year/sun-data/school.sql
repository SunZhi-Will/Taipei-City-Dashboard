-- 學區數量（index: `school`）
-- 2. `dashboard` 資料庫

-- 2.1 建立 school_tpe 資料表
CREATE TABLE school_tpe (
  district VARCHAR(10) NOT NULL,
  count INT NOT NULL,
  PRIMARY KEY (district)
);

-- 2.2 建立 school_ntpc 資料表
CREATE TABLE school_ntpc (
  district VARCHAR(10) NOT NULL,
  count INT NOT NULL,
  PRIMARY KEY (district)
); 


-- 1. `dashboardmanager` 資料庫

-- 1.1 插入 `components` 資料表
INSERT INTO components (
  index, name
)
VALUES (
  'school',
  '學區數量'
);

-- 1.2 插入 `component_charts` 資料表
INSERT INTO component_charts (
  index, color, types, unit
)
VALUES (
  'school',
  ARRAY['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEEAD', '#D4A5A5', '#9B59B6', '#3498DB', '#E67E22', '#2ECC71', '#F1C40F', '#1ABC9C'],
  ARRAY['DistrictChart', 'ColumnChart'],
  '個'
);

-- 1.3 插入 `component_maps` 資料表
INSERT INTO component_maps (
  index, title, type, source, property
) VALUES (
  'school_map',
  '學區分布',
  'circle',
  'geojson',
  '[
    {"key": "district", "name": "行政區"},
    {"key": "count", "name": "學區數量"}
  ]'::json
);

-- 1.4 插入 `query_charts` 資料表

-- 1.4.1 台北市
INSERT INTO query_charts (
  index, time_from, source, short_desc, long_desc, use_case, links,
  contributors, created_at, updated_at, query_type, query_chart,
  city
)
VALUES (
  'school',
  'static',
  '教育局',
  '記錄臺北市各行政區學區數量分布',
  '本資料集收錄臺北市各行政區學區數量資訊，包含行政區名稱、學區數量等欄位。資料來源涵蓋各級學校，能夠反映學區在城市空間中的分布密度，具備地理參照資訊，適合用於地圖視覺化與空間分布分析。此資料可配合人口資料，探討教育資源分配與潛在缺口，亦可作為政府推動教育政策之參考依據。',
  '可應用於城市教育資源規劃、學區分布分析、教育資源覆蓋範圍評估與資源分布不均之偵測。適合支援如「高人口密度區域學區覆蓋率檢查」、「教育資源分配分析」等場景。',
  ARRAY['https://data.taipei/dataset/detail?id=your-dataset-id'],
  ARRAY['doit'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    district AS x_axis,
    count AS data
  FROM school_tpe
) AS t
ORDER BY
  ARRAY_POSITION(
    ARRAY['北投區','士林區','內湖區','南港區','松山區','信義區','中山區','大同區','中正區','萬華區','大安區','文山區'],
    t.x_axis
  );$SQL$,
  'taipei'
);

-- 1.4.2 雙北
INSERT INTO query_charts (
  index, time_from, source, short_desc, long_desc, use_case, links,
  contributors, created_at, updated_at, query_type, query_chart,
  city
)
VALUES (
  'school',
  'static',
  '教育局',
  '記錄雙北地區各行政區學區數量分布',
  '本資料集收錄雙北地區各行政區學區數量資訊，包含行政區名稱、學區數量等欄位。資料來源涵蓋各級學校，能夠反映學區在城市空間中的分布密度，具備地理參照資訊，適合用於地圖視覺化與空間分布分析。此資料可配合人口資料，探討教育資源分配與潛在缺口，亦可作為政府推動教育政策之參考依據。',
  '可應用於城市教育資源規劃、學區分布分析、教育資源覆蓋範圍評估與資源分布不均之偵測。適合支援如「高人口密度區域學區覆蓋率檢查」、「教育資源分配分析」等場景。',
  ARRAY[
    'https://data.taipei/dataset/detail?id=your-dataset-id',
    'https://data.ntpc.gov.tw/datasets/your-dataset-id'
  ],
  ARRAY['doit','ntpc'],
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  'two_d',
  $SQL$SELECT * FROM (
  SELECT
    district AS x_axis,
    count AS data
  FROM (
    SELECT district, count FROM school_tpe
    UNION ALL
    SELECT district, count FROM school_ntpc
  ) AS combined
  GROUP BY district, count
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

