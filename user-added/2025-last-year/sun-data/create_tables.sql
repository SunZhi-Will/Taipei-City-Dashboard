-- 建立台北市各區老人福利機構統計資料表
CREATE TABLE elderly_tpe (
    town VARCHAR(10) PRIMARY KEY,
    bed_for_caring INTEGER NOT NULL DEFAULT 0,
    bed_for_nursing INTEGER NOT NULL DEFAULT 0,
    bed_for_longterm INTEGER NOT NULL DEFAULT 0,
    bed_for_azh INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE elderly_tpe IS '台北市各區老人福利機構床位統計';
COMMENT ON COLUMN elderly_tpe.town IS '行政區';
COMMENT ON COLUMN elderly_tpe.bed_for_caring IS '養護床位';
COMMENT ON COLUMN elderly_tpe.bed_for_nursing IS '安養床位';
COMMENT ON COLUMN elderly_tpe.bed_for_longterm IS '長照床位';
COMMENT ON COLUMN elderly_tpe.bed_for_azh IS '失智床位';

-- 建立新北市各區老人福利機構統計資料表
CREATE TABLE elderly_ntpc (
    town VARCHAR(10) PRIMARY KEY,
    bed_for_caring INTEGER NOT NULL DEFAULT 0,
    bed_for_nursing INTEGER NOT NULL DEFAULT 0,
    bed_for_longterm INTEGER NOT NULL DEFAULT 0,
    bed_for_azh INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE elderly_ntpc IS '新北市各區老人福利機構床位統計';
COMMENT ON COLUMN elderly_ntpc.town IS '行政區';
COMMENT ON COLUMN elderly_ntpc.bed_for_caring IS '養護床位';
COMMENT ON COLUMN elderly_ntpc.bed_for_nursing IS '安養床位';
COMMENT ON COLUMN elderly_ntpc.bed_for_longterm IS '長照床位';
COMMENT ON COLUMN elderly_ntpc.bed_for_azh IS '失智床位';

-- 新增台北市資料
INSERT INTO elderly_tpe (town, bed_for_caring, bed_for_nursing, bed_for_longterm, bed_for_azh) VALUES
('中山區', 317, 0, 0, 0),
('中正區', 106, 0, 0, 0),
('信義區', 57, 0, 0, 0),
('內湖區', 206, 0, 5, 0),
('北投區', 997, 225, 0, 0),
('南港區', 20, 0, 0, 0),
('士林區', 438, 153, 176, 0),
('大同區', 401, 0, 0, 0),
('大安區', 213, 0, 9, 0),
('文山區', 617, 555, 132, 0),
('松山區', 131, 0, 0, 0),
('萬華區', 372, 0, 0, 62);

-- 新增新北市資料
INSERT INTO elderly_ntpc (town, bed_for_caring, bed_for_nursing, bed_for_longterm, bed_for_azh) VALUES
('三峽區', 1044, 0, 0, 0),
('三芝區', 252, 212, 0, 66),
('三重區', 557, 0, 0, 0),
('中和區', 1196, 0, 0, 0),
('五股區', 122, 0, 0, 0),
('八里區', 25, 53, 0, 0),
('土城區', 358, 0, 0, 0),
('新店區', 844, 0, 16, 0),
('新莊區', 792, 0, 25, 0),
('板橋區', 1454, 0, 15, 0),
('林口區', 43, 0, 41, 0),
('樹林區', 303, 0, 0, 0),
('永和區', 350, 0, 0, 0),
('汐止區', 978, 71, 5, 0),
('泰山區', 84, 0, 0, 0),
('鶯歌區', 136, 0, 0, 0);

-- 刪除已新增的組件相關資料
DELETE FROM query_charts WHERE index = 'elderly';
DELETE FROM component_charts WHERE index = 'elderly';
DELETE FROM components WHERE index = 'elderly';

-- 新增老人福利機構組件資料
INSERT INTO components (
    index,
    name
) VALUES (
    'elderly',
    '老人福利機構'
);

-- 新增老人福利機構圖表組件資料
INSERT INTO component_charts (
    index,
    color,
    types,
    unit
) VALUES (
    'elderly',
    ARRAY['#fc038c'],
    ARRAY['HeatmapChart', 'DistrictChart'],
    '床'
);

-- 新增查詢圖表資料
-- 台北市資料
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
) VALUES (
    'elderly',
    'static',
    '衛生局',
    '記錄台北市各區老人福利機構床位統計資料',
    '本資料集記錄台北市各行政區老人福利機構的床位數量，包含養護、安養、長照及失智床位的統計資訊，能夠反映各區老人福利資源的分布情況。資料來源涵蓋各類型的老人福利機構，包括養護型、長照型、失智照顧等機構，可用於分析各區照護資源的配置狀況。',
    '可應用於老人福利資源分布分析、長照資源配置規劃、跨區域照護資源比較等場景。適合支援如「各區養護資源盤點」、「長照資源配置評估」等應用。也可搭配人口結構資料，進行跨域整合分析，評估資源配置是否符合在地需求。',
    ARRAY['https://data.taipei/dataset/detail/metadata?id=6f7d5b30-8a68-4ea4-8aa3-3fd99e19ab4c'],
    ARRAY['doit'],
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'three_d',
    $SQL$WITH bed_types AS (
    SELECT unnest(ARRAY['養護床位', '安養床位', '長照床位', '失智床位']) AS bed_type
),
districts AS (
    SELECT unnest(ARRAY['北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區', '萬華區', '大安區', '文山區']) AS district
),
all_combinations AS (
    SELECT 
        d.district AS x_axis,
        b.bed_type AS y_axis
    FROM districts d
    CROSS JOIN bed_types b
),
bed_data AS (
    SELECT 
        town AS x_axis,
        '養護床位' AS y_axis,
        bed_for_caring AS data
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '安養床位',
        bed_for_nursing
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '長照床位',
        bed_for_longterm
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '失智床位',
        bed_for_azh
    FROM elderly_tpe
)
SELECT 
    ac.x_axis,
    ac.y_axis,
    COALESCE(bd.data, 0) AS data
FROM all_combinations ac
LEFT JOIN bed_data bd ON ac.x_axis = bd.x_axis AND ac.y_axis = bd.y_axis
ORDER BY 
    ARRAY_POSITION(ARRAY['北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區', '萬華區', '大安區', '文山區'], ac.x_axis),
    ARRAY_POSITION(ARRAY['養護床位', '安養床位', '長照床位', '失智床位'], ac.y_axis);$SQL$,
    'taipei'
);

-- 雙北資料
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
) VALUES (
    'elderly',
    'static',
    '衛生局',
    '記錄雙北地區老人福利機構床位統計資料',
    '本資料集記錄雙北地區各行政區老人福利機構的床位數量，包含養護、安養、長照及失智床位的統計資訊，能夠反映雙北各區老人福利資源的分布情況。資料來源涵蓋各類型的老人福利機構，包括養護型、長照型、失智照顧等機構，可用於分析跨區域照護資源的配置狀況。',
    '可應用於雙北老人福利資源整體規劃、跨區域照護資源配置分析、區域資源差異比較等場景。適合支援如「雙北養護資源整合評估」、「跨區域長照資源配置分析」等應用。也可搭配人口結構與交通資料，進行跨域整合分析，評估資源配置的區域平衡性。',
    ARRAY[
        'https://data.taipei/dataset/detail/metadata?id=6f7d5b30-8a68-4ea4-8aa3-3fd99e19ab4c',
        'https://data.ntpc.gov.tw/datasets/4DBD5B5F-6CE7-4168-B3F9-656B168C1C3C'
    ],
    ARRAY['doit','ntpc'],
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'three_d',
    $SQL$WITH bed_types AS (
    SELECT unnest(ARRAY['養護床位', '安養床位', '長照床位', '失智床位']) AS bed_type
),
districts AS (
    SELECT unnest(ARRAY[
        '北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區',
        '萬華區', '大安區', '文山區', '新莊區', '淡水區', '汐止區', '板橋區', '三重區', '樹林區',
        '土城區', '蘆洲區', '中和區', '永和區', '新店區', '鶯歌區', '三峽區', '瑞芳區', '五股區',
        '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區',
        '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'
    ]) AS district
),
all_combinations AS (
    SELECT 
        d.district AS x_axis,
        b.bed_type AS y_axis
    FROM districts d
    CROSS JOIN bed_types b
),
bed_data AS (
    SELECT 
        town AS x_axis,
        '養護床位' AS y_axis,
        bed_for_caring AS data
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '安養床位',
        bed_for_nursing
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '長照床位',
        bed_for_longterm
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town,
        '失智床位',
        bed_for_azh
    FROM elderly_tpe
    UNION ALL
    SELECT 
        town AS x_axis,
        '養護床位' AS y_axis,
        bed_for_caring AS data
    FROM elderly_ntpc
    UNION ALL
    SELECT 
        town,
        '安養床位',
        bed_for_nursing
    FROM elderly_ntpc
    UNION ALL
    SELECT 
        town,
        '長照床位',
        bed_for_longterm
    FROM elderly_ntpc
    UNION ALL
    SELECT 
        town,
        '失智床位',
        bed_for_azh
    FROM elderly_ntpc
)
SELECT 
    ac.x_axis,
    ac.y_axis,
    COALESCE(bd.data, 0) AS data
FROM all_combinations ac
LEFT JOIN bed_data bd ON ac.x_axis = bd.x_axis AND ac.y_axis = bd.y_axis
ORDER BY 
    ARRAY_POSITION(ARRAY[
        '北投區', '士林區', '內湖區', '南港區', '松山區', '信義區', '中山區', '大同區', '中正區',
        '萬華區', '大安區', '文山區', '新莊區', '淡水區', '汐止區', '板橋區', '三重區', '樹林區',
        '土城區', '蘆洲區', '中和區', '永和區', '新店區', '鶯歌區', '三峽區', '瑞芳區', '五股區',
        '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區',
        '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'
    ], ac.x_axis),
    ARRAY_POSITION(ARRAY['養護床位', '安養床位', '長照床位', '失智床位'], ac.y_axis);$SQL$,
    'metrotaipei'
); 
