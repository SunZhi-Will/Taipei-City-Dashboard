-- ===========================================================
-- 黑客松功能整合 - Dashboardmanager DB 組件設定
-- 適用 DB: dashboardmanager (container: postgres-manager)
-- 執行: docker exec -i postgres-manager psql -U postgres -d dashboardmanager < 03_dashboardmanager_inserts.sql
-- ===========================================================

-- ─────────────────────────────────────────────
-- 0. 安全前置：確認冪等性（先刪後插）
-- ─────────────────────────────────────────────
DELETE FROM public.query_charts
WHERE index IN (
    'aed_map','aed_district_tpe',
    'indigenous_district_tpe','indigenous_group_tpe',
    'migrant_workers_tpe',
    'long_term_care_abc_map','long_term_care_abc_district_tpe'
);

DELETE FROM public.component_charts
WHERE index IN (
    'aed_map','aed_district_tpe',
    'indigenous_district_tpe','indigenous_group_tpe',
    'migrant_workers_tpe',
    'long_term_care_abc_map','long_term_care_abc_district_tpe'
);

DELETE FROM public.component_maps
WHERE index IN ('aed_map','long_term_care_abc_tpe','long_term_care_abc_metrotaipei');

DELETE FROM public.components
WHERE index IN (
    'aed_map','aed_district_tpe',
    'indigenous_district_tpe','indigenous_group_tpe',
    'migrant_workers_tpe',
    'long_term_care_abc_map','long_term_care_abc_district_tpe'
);

DELETE FROM public.dashboards
WHERE index IN (
    'aed_tpe','indigenous_social_tpe',
    'migrant_workers_tpe','long_term_care_abc_tpe_dashboard'
);

-- ─────────────────────────────────────────────
-- 1. component_maps  (地圖圖層設定)
-- ─────────────────────────────────────────────
INSERT INTO public.component_maps (index, title, type, source, size, icon, paint, property)
VALUES
-- AED 台北市 (靜態 GeoJSON: /mapData/aed_map.geojson)
(
    'aed_map',
    'AED 自動體外除顫器',
    'circle',
    'geojson',
    NULL,
    NULL,
    '{"circle-color":"#E74C3C","circle-radius":6,"circle-opacity":0.85,"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}',
    '[{"key":"name","name":"機構名稱"},{"key":"district","name":"行政區"},{"key":"category","name":"場所類別"},{"key":"type","name":"場所類型"},{"key":"location_desc","name":"設置位置"}]'
),
-- 長照ABC據點 台北市 (靜態 GeoJSON: /mapData/long_term_care_abc_tpe.geojson)
(
    'long_term_care_abc_tpe',
    '長照ABC服務型據點(台北)',
    'circle',
    'geojson',
    NULL,
    NULL,
    '{"circle-color":["match",["get","O_ABC"],"A","#E74C3C","B","#F39C12","C","#3498DB","BA","#9B59B6","#7F8C8D"],"circle-radius":5,"circle-opacity":0.8,"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}',
    '[{"key":"機構名稱","name":"機構名稱"},{"key":"機構種類","name":"種類代碼"},{"key":"區","name":"行政區"},{"key":"O_ABC","name":"服務類型"},{"key":"特約服務項目","name":"特約服務"}]'
),
-- 長照ABC據點 雙北 (靜態 GeoJSON: /mapData/long_term_care_abc_metrotaipei.geojson)
(
    'long_term_care_abc_metrotaipei',
    '長照ABC服務型據點(雙北)',
    'circle',
    'geojson',
    NULL,
    NULL,
    '{"circle-color":["match",["get","O_ABC"],"A","#E74C3C","B","#F39C12","C","#3498DB","BA","#9B59B6","#7F8C8D"],"circle-radius":5,"circle-opacity":0.8,"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}',
    '[{"key":"機構名稱","name":"機構名稱"},{"key":"機構種類","name":"種類代碼"},{"key":"區","name":"行政區"},{"key":"O_ABC","name":"服務類型"},{"key":"特約服務項目","name":"特約服務"}]'
);

-- ─────────────────────────────────────────────
-- 2. component_charts  (圖表類型與顏色)
-- ─────────────────────────────────────────────
INSERT INTO public.component_charts (index, color, types, unit)
VALUES
-- AED 地圖圖例
('aed_map',             '{#E74C3C}',                                '{MapLegend}',              NULL),
-- AED 行政區統計
('aed_district_tpe',    '{#E74C3C,#C0392B}',                        '{BarChart}',               '台'),
-- 原住民族 - 行政區別  (平地/山地兩種)
('indigenous_district_tpe', '{#FF6B35,#F7C59F}',                   '{ColumnChart,BarChart}',   '人'),
-- 原住民族 - 族別 (顏色數量需 >= 系列數，系統自動循環)
('indigenous_group_tpe', '{#8E44AD,#A569BD,#C39BD3,#D7BDE2,#F8C471,#F39C12,#E74C3C,#A93226,#0097A7,#00BCD4,#4CAF50,#8BC34A,#FF9800,#FF5722,#795548,#607D8B,#9E9E9E}',
    '{BarChart}', '人'),
-- 受聘僱移工 台北市
('migrant_workers_tpe', '{#3498DB,#85C1E9,#1ABC9C,#A3E4D7,#F39C12,#F8C471}',
    '{ColumnChart,DonutChart}', '人'),
-- 長照ABC 地圖圖例
('long_term_care_abc_map',         '{#E74C3C,#F39C12,#3498DB,#9B59B6}',    '{MapLegend}',      NULL),
-- 長照ABC 行政區統計
('long_term_care_abc_district_tpe', '{#4CB495,#27AE60,#1ABC9C}',            '{BarChart,DonutChart}', '所');

-- ─────────────────────────────────────────────
-- 3. components  (組件登錄)
-- ─────────────────────────────────────────────
INSERT INTO public.components (index, name)
VALUES
('aed_map',                     'AED 地圖'),
('aed_district_tpe',            'AED 行政區分布'),
('indigenous_district_tpe',     '原住民族行政區人口'),
('indigenous_group_tpe',        '原住民族族別人口'),
('migrant_workers_tpe',         '受聘僱移工（臺北市）'),
('long_term_care_abc_map',      '長照ABC 地圖'),
('long_term_care_abc_district_tpe', '長照ABC 行政區統計');

-- ─────────────────────────────────────────────
-- 4. query_charts  (API 查詢設定)
-- ─────────────────────────────────────────────

-- 4-1. AED 地圖 (map_legend) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'aed_map', NULL,
    ARRAY[(SELECT id FROM public.component_maps WHERE index = 'aed_map')],
    '{}',
    'static', NULL, 0, NULL,
    '衛生局/消防局',
    '顯示台北市 AED 自動體外除顫器地點分布。',
    '自動體外除顫器 (AED) 是一種可攜式急救設備，在心臟驟停發生時能自動分析心律並施予電擊。此圖資顯示台北市公共場所 AED 的地理分布，協助民眾快速找到最近的急救設備。',
    '結合人流熱點、醫療機構位置進行覆蓋率分析，輔助衛生局規劃 AED 佈建優先區域。',
    '{https://data.taipei/dataset/detail?id=aed-taipei}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    'SELECT unnest(array[''AED 自動體外除顫器'']) as name, ''circle'' as type',
    NULL,
    'taipei'
);

-- 4-2. AED 行政區統計 (two_d) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'aed_district_tpe', NULL, '{}', '{}',
    'static', NULL, 0, NULL,
    '衛生局/消防局',
    '顯示台北市各行政區 AED 數量分布。',
    '依行政區統計台北市 AED 自動體外除顫器的設置數量，反映各區緊急救護資源的相對豐富程度。設置密度高的區域通常是商業中心、學校或大型公共設施集中地帶。',
    '政策制定者可藉此評估各行政區急救設備覆蓋率，做為優先補充 AED 的參考依據。',
    '{https://data.taipei/dataset/detail?id=aed-taipei}',
    '{doit}',
    NOW(), NOW(),
    'two_d',
    'SELECT district AS x_axis, COUNT(*) AS data
FROM public.aed_tpe
GROUP BY district
ORDER BY data DESC',
    NULL,
    'taipei'
);

-- 4-3. 原住民族 行政區別 (three_d) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'indigenous_district_tpe', NULL, '{}', '{}',
    'static', NULL, 0, NULL,
    '主計處/民政局',
    '顯示台北市原住民族人口依行政區分布（平地族/山地族）。',
    '此圖呈現台北市各行政區原住民族人口結構，區分平地原住民與山地原住民兩大類別。資料來源為台北市政府統計資料，按行政區及性別分類，可協助了解原住民族在都市的分布情形與聚集態樣。',
    '社福政策制定者可據此評估原住民族族人的服務需求分布，規劃語言、文化、就業輔導資源的佈建重點。',
    '{https://data.taipei/dataset/detail?id=indigenous-population-taipei}',
    '{doit}',
    NOW(), NOW(),
    'three_d',
    'SELECT
    district AS x_axis,
    gender AS y_axis,
    SUM(total) AS data
FROM public.indigenous_by_district_tpe
WHERE gender != ''計''
  AND year = (SELECT MAX(year) FROM public.indigenous_by_district_tpe)
  AND month = (SELECT MAX(month) FROM public.indigenous_by_district_tpe
               WHERE year = (SELECT MAX(year) FROM public.indigenous_by_district_tpe))
GROUP BY district, gender
ORDER BY SUM(total) DESC, gender',
    NULL,
    'taipei'
);

-- 4-4. 原住民族 族別 (two_d) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'indigenous_group_tpe', NULL, '{}', '{}',
    'static', NULL, 0, NULL,
    '主計處/原住民族委員會',
    '顯示台北市原住民族各族別人口數量。',
    '台北市為全台原住民族人口最集中的都市之一。此圖依族別呈現各族在台北市的人口規模，涵蓋 16 個官方認定族別及未登記人口，反映都市原住民族的多元組成。',
    '文化主管機關可依此規劃族群文化活動與傳承資源；社服單位可依族別分布評估語言服務優先級。',
    '{https://data.taipei/dataset/detail?id=indigenous-population-taipei}',
    '{doit}',
    NOW(), NOW(),
    'two_d',
    'SELECT ethnic_group AS x_axis, SUM(population) AS data
FROM (
    SELECT ''阿美族'' AS ethnic_group, population_amis AS population FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''泰雅族'', population_atayal FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''排灣族'', population_paiwan FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''布農族'', population_bunun FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''魯凱族'', population_rukai FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''卑南族'', population_pinan FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''鄒族'', population_tsou FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''賽夏族'', population_saisiyat FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''雅美族(達悟族)'', population_yami FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''邵族'', population_thao FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''噶瑪蘭族'', population_kavalan FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''太魯閣族'', population_truku FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''撒奇萊雅族'', population_sakizaya FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''賽德克族'', population_seediq FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''拉阿魯哇族'', population_laaruwa FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''卡那卡那富族'', population_kanakanavu FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
    UNION ALL SELECT ''未登記'', unreported FROM public.indigenous_by_group_tpe
    WHERE gender = ''計'' AND year = (SELECT MAX(year) FROM public.indigenous_by_group_tpe)
) g
GROUP BY ethnic_group
ORDER BY data DESC',
    NULL,
    'taipei'
);

-- 4-5. 受聘僱移工 台北市 (three_d) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'migrant_workers_tpe', NULL, '{}', '{}',
    'static', NULL, 0, NULL,
    '勞動局/勞動部',
    '顯示台北市受聘僱移工依國籍與行業別分布。',
    '依最新月份統計台北市受聘僱外籍移工的國籍與行業別分布，包含印尼、菲律賓、越南、泰國等主要來源國，以及農漁牧、製造業、社會福利、家庭幫傭等行業別。',
    '勞動主管機關可據此掌握移工來源結構與行業分布趨勢，作為勞動力政策規劃與移工輔導服務的參考。NGO 單位可了解主要服務族群。',
    '{https://data.taipei/dataset/detail?id=migrant-workers-taipei}',
    '{doit}',
    NOW(), NOW(),
    'three_d',
    'SELECT
    job_type AS x_axis,
    nationality AS y_axis,
    SUM(count) AS data
FROM public.migrant_workers_employed_tpe
WHERE year = (SELECT MAX(year) FROM public.migrant_workers_employed_tpe)
  AND month = (SELECT MAX(month) FROM public.migrant_workers_employed_tpe
               WHERE year = (SELECT MAX(year) FROM public.migrant_workers_employed_tpe))
GROUP BY job_type, nationality
ORDER BY SUM(count) DESC',
    NULL,
    'taipei'
);

-- 4-6. 長照ABC 地圖 (map_legend) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'long_term_care_abc_map', NULL,
    ARRAY[(SELECT id FROM public.component_maps WHERE index = 'long_term_care_abc_tpe')],
    '{}',
    'static', NULL, 0, NULL,
    '衛生福利部/台北市社會局',
    '顯示台北市長照 ABC 服務型據點地圖。',
    '長照 2.0 政策推動 A-B-C 三級服務體系：A 社區整合型服務中心（旗艦店）、B 複合型服務中心（專賣店）、C 巷弄長照站（柑仔店）。此圖呈現台北市各類型據點的地理分布，協助民眾及照護者快速找到就近服務。',
    '家庭照護者可利用此圖查詢最近長照據點；福利主管機關可分析空白服務區域，規劃新增據點優先位置。',
    '{https://www.mohw.gov.tw/cp-16-48299-1.html}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    'SELECT unnest(array[''A 社區整合型'',''B 複合型'',''C 巷弄長照站'',''BA 交通接送'']) as name, ''circle'' as type',
    NULL,
    'taipei'
);

-- 4-7. 長照ABC 地圖 (map_legend) — metrotaipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'long_term_care_abc_map', NULL,
    ARRAY[(SELECT id FROM public.component_maps WHERE index = 'long_term_care_abc_metrotaipei')],
    '{}',
    'static', NULL, 0, NULL,
    '衛生福利部/雙北社會局',
    '顯示雙北長照 ABC 服務型據點地圖。',
    '顯示雙北（台北市＋新北市）長照 ABC 三類服務型據點的地理分布。',
    '跨市照護規劃的參考依據。',
    '{https://www.mohw.gov.tw/cp-16-48299-1.html}',
    '{doit,ntpc}',
    NOW(), NOW(),
    'map_legend',
    'SELECT unnest(array[''A 社區整合型'',''B 複合型'',''C 巷弄長照站'',''BA 交通接送'']) as name, ''circle'' as type',
    NULL,
    'metrotaipei'
);

-- 4-8. 長照ABC 行政區統計 (two_d) — taipei
INSERT INTO public.query_charts
    (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit,
     source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at,
     query_type, query_chart, query_history, city)
VALUES (
    'long_term_care_abc_district_tpe', NULL, '{}', '{}',
    'static', NULL, 0, NULL,
    '衛生福利部/台北市社會局',
    '顯示台北市各行政區長照ABC據點數量分布。',
    '依台北市各行政區統計 A、B、C、BA 各類型長照據點總數，協助了解各區長照資源的豐富程度與分布均衡性。',
    '可識別長照資源不足的行政區，作為新設據點、資源補強的政策依據。',
    '{https://www.mohw.gov.tw/cp-16-48299-1.html}',
    '{doit}',
    NOW(), NOW(),
    'two_d',
    'SELECT district AS x_axis, COUNT(*) AS data
FROM public.long_term_care_abc_tpe
WHERE city = ''臺北市''
GROUP BY district
ORDER BY data DESC',
    NULL,
    'taipei'
);

-- ─────────────────────────────────────────────
-- 5. dashboards  (儀表板群組)
-- ─────────────────────────────────────────────
INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
VALUES
(
    'aed_tpe',
    'AED 分布',
    ARRAY[
        (SELECT id FROM public.components WHERE index = 'aed_map'),
        (SELECT id FROM public.components WHERE index = 'aed_district_tpe')
    ]::integer[],
    'health',
    NOW(), NOW()
),
(
    'indigenous_social_tpe',
    '原住民族人口',
    ARRAY[
        (SELECT id FROM public.components WHERE index = 'indigenous_district_tpe'),
        (SELECT id FROM public.components WHERE index = 'indigenous_group_tpe')
    ]::integer[],
    'people',
    NOW(), NOW()
),
(
    'migrant_workers_tpe',
    '受聘僱移工',
    ARRAY[
        (SELECT id FROM public.components WHERE index = 'migrant_workers_tpe')
    ]::integer[],
    'people',
    NOW(), NOW()
),
(
    'long_term_care_abc_tpe_dashboard',
    '長照ABC據點',
    ARRAY[
        (SELECT id FROM public.components WHERE index = 'long_term_care_abc_map'),
        (SELECT id FROM public.components WHERE index = 'long_term_care_abc_district_tpe')
    ]::integer[],
    'elderly',
    NOW(), NOW()
);

-- ─────────────────────────────────────────────
-- 6. 加入公開群組 (group_id=2 為 public)
-- ─────────────────────────────────────────────
INSERT INTO public.dashboard_groups (dashboard_id, group_id)
SELECT id, 2
FROM public.dashboards
WHERE index IN (
    'aed_tpe', 'indigenous_social_tpe',
    'migrant_workers_tpe', 'long_term_care_abc_tpe_dashboard'
)
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- 7. 同步 sequences
-- ─────────────────────────────────────────────
SELECT setval('public.dashboards_id_seq',
    (SELECT COALESCE(MAX(id), 360) FROM public.dashboards), true);

-- ─────────────────────────────────────────────
-- 驗證
-- ─────────────────────────────────────────────
SELECT 'components' AS tbl, COUNT(*) FROM public.components
WHERE index IN ('aed_map','aed_district_tpe','indigenous_district_tpe',
                'indigenous_group_tpe','migrant_workers_tpe',
                'long_term_care_abc_map','long_term_care_abc_district_tpe')
UNION ALL
SELECT 'component_maps', COUNT(*) FROM public.component_maps
WHERE index IN ('aed_map','long_term_care_abc_tpe','long_term_care_abc_metrotaipei')
UNION ALL
SELECT 'component_charts', COUNT(*) FROM public.component_charts
WHERE index IN ('aed_map','aed_district_tpe','indigenous_district_tpe',
                'indigenous_group_tpe','migrant_workers_tpe',
                'long_term_care_abc_map','long_term_care_abc_district_tpe')
UNION ALL
SELECT 'query_charts', COUNT(*) FROM public.query_charts
WHERE index IN ('aed_map','aed_district_tpe','indigenous_district_tpe',
                'indigenous_group_tpe','migrant_workers_tpe',
                'long_term_care_abc_map','long_term_care_abc_district_tpe')
UNION ALL
SELECT 'dashboards', COUNT(*) FROM public.dashboards
WHERE index IN ('aed_tpe','indigenous_social_tpe',
                'migrant_workers_tpe','long_term_care_abc_tpe_dashboard');
