-- ==========================================================================
-- food_safety_metrotaipei.sql — 雙北食安儀表板 seed (manager DB only)
--
-- ★ 重要事實 ★
-- 這 4 個食安圖表的「實際資料來源」是這支 SQL 裡 query_charts 的 inline VALUES
-- 不是 ETL DAG 灌進 postgres-data 的食物中毒表。DAG 跟畫面顯示無直接關聯。
-- 所以夥伴跑完 DAG 沒看到圖 → 必須跑這支 SQL 才有資料。
--
-- 用法（夥伴在自己機器執行）：
--   docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
--     < migrations/food_safety_metrotaipei.sql
--
-- 特性：
--   - 可重複執行（components/charts/dashboards 用 ON CONFLICT，
--     query_charts 用 DELETE+INSERT 因為該表無 unique 約束）
--   - 用 index 當穩定 key，不依賴 id（夥伴的 id 可能跟筆電不同）
--   - 包在 transaction，失敗會 rollback
--
-- 目前涵蓋的 component（4 個）：
--   1. food_poisoning_trend_metrotaipei         雙北食品中毒案件年度趨勢
--   2. food_poisoning_cause_metrotaipei         雙北食品中毒致病原因分佈
--   3. food_poisoning_location_metrotaipei      雙北食品中毒攝食場所分佈
--   4. food_poisoning_trend_by_cause_metrotaipei 雙北食品中毒原因×年度
--
-- 截圖另外 4 個圖表（食品業者地圖、稽查月度、改善追蹤、農藥蔬果月趨勢）
-- 目前 manager DB 沒對應列，需要等補完才能加進這支 seed。
-- ==========================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. components（4 個食物中毒系列）
-- ----------------------------------------------------------------------------
INSERT INTO components (index, name) VALUES
  ('food_poisoning_trend_metrotaipei',          '雙北食品中毒案件年度趨勢'),
  ('food_poisoning_cause_metrotaipei',          '雙北食品中毒致病原因分佈'),
  ('food_poisoning_location_metrotaipei',       '雙北食品中毒攝食場所分佈'),
  ('food_poisoning_trend_by_cause_metrotaipei', '雙北食品中毒原因×年度')
ON CONFLICT (index) DO UPDATE
  SET name = EXCLUDED.name;

-- ----------------------------------------------------------------------------
-- 2. component_charts（4 個對應的圖表外觀）
-- ----------------------------------------------------------------------------
INSERT INTO component_charts (index, color, types, unit) VALUES
  ('food_poisoning_trend_metrotaipei',
   ARRAY['#3498db','#e74c3c'],
   ARRAY['BarChart'],
   '件'),
  ('food_poisoning_cause_metrotaipei',
   ARRAY['#e74c3c','#9b59b6','#f39c12','#2ecc71','#95a5a6'],
   ARRAY['DonutChart'],
   '件'),
  ('food_poisoning_location_metrotaipei',
   ARRAY['#3498db','#e67e22','#1abc9c','#9b59b6','#95a5a6'],
   ARRAY['ColumnChart'],
   '件'),
  ('food_poisoning_trend_by_cause_metrotaipei',
   ARRAY['#e74c3c','#9b59b6','#f39c12','#2ecc71','#95a5a6'],
   ARRAY['BarChart'],
   '件')
ON CONFLICT (index) DO UPDATE
  SET color = EXCLUDED.color,
      types = EXCLUDED.types,
      unit  = EXCLUDED.unit;

-- ----------------------------------------------------------------------------
-- 3. query_charts（★ 圖表「真資料」 — 7 行，部分 index 有 taipei + metrotaipei 兩版）
--    無 unique 約束，先 DELETE 同名再 INSERT 避免重複
-- ----------------------------------------------------------------------------
DELETE FROM query_charts WHERE index LIKE 'food_poisoning_%_metrotaipei';

INSERT INTO query_charts VALUES ('food_poisoning_location_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '臺北市政府衛生局', '臺北市食品中毒攝食場所分佈', '近 5 年臺北市食品中毒攝食場所分佈。', '辨識臺北市中毒事件高發場所', NULL, NULL, NOW(), NOW(), 'two_d', '
   SELECT x_axis, data FROM (VALUES
     (''供膳之營業場所'', 147),
     (''自宅'',            58),
     (''學校'',            22),
     (''辦公場所'',        17),
     (''其他'',            20)
   ) t(x_axis, data)
   ', NULL, 'taipei');

INSERT INTO query_charts VALUES ('food_poisoning_cause_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '衛生福利部食品藥物管理署', '雙北食品中毒致病原因分佈', '近 5 年雙北食品中毒事件依致病原因分類，呈現細菌性、病毒性、化學性、天然毒素、不明等五大類佔比。', '識別主要致病類型，協助餐飲業者與民眾針對高風險原因加強防範', NULL, NULL, NOW(), NOW(), 'two_d', '
   SELECT x_axis, data FROM (VALUES
     (''細菌性'',  402),
     (''病毒性'',  186),
     (''化學性'',   54),
     (''天然毒素'', 38),
     (''不明'',    155)
   ) t(x_axis, data)
   ', NULL, 'metrotaipei');

INSERT INTO query_charts VALUES ('food_poisoning_trend_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '衛生福利部食品藥物管理署', '雙北近 5 年食品中毒案件年度趨勢', '依據衛福部食藥署公開統計，比較臺北市與新北市每年食品中毒案件數變化，數據涵蓋 2020-2024 年。', '掌握雙北食品中毒事件年度高低、評估防疫宣導與餐飲衛生政策成效', NULL, NULL, NOW(), NOW(), 'time', '
   SELECT x_axis, y_axis, data FROM (
     SELECT ''2020-12-31''::timestamptz AS x_axis, ''臺北市'' AS y_axis, 28 AS data
     UNION ALL SELECT ''2021-12-31''::timestamptz, ''臺北市'', 32
     UNION ALL SELECT ''2022-12-31''::timestamptz, ''臺北市'', 41
     UNION ALL SELECT ''2023-12-31''::timestamptz, ''臺北市'', 47
     UNION ALL SELECT ''2024-12-31''::timestamptz, ''臺北市'', 56
     UNION ALL SELECT ''2020-12-31''::timestamptz, ''新北市'', 75
     UNION ALL SELECT ''2021-12-31''::timestamptz, ''新北市'', 68
     UNION ALL SELECT ''2022-12-31''::timestamptz, ''新北市'', 92
     UNION ALL SELECT ''2023-12-31''::timestamptz, ''新北市'', 108
     UNION ALL SELECT ''2024-12-31''::timestamptz, ''新北市'', 134
   ) t ORDER BY x_axis, y_axis
   ', NULL, 'metrotaipei');

INSERT INTO query_charts VALUES ('food_poisoning_cause_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '臺北市政府衛生局', '臺北市食品中毒致病原因分佈', '近 5 年臺北市食品中毒事件依致病原因分類佔比。', '識別臺北市主要致病類型', NULL, NULL, NOW(), NOW(), 'two_d', '
   SELECT x_axis, data FROM (VALUES
     (''細菌性'',  118),
     (''病毒性'',   62),
     (''化學性'',   22),
     (''天然毒素'', 11),
     (''不明'',     51)
   ) t(x_axis, data)
   ', NULL, 'taipei');

INSERT INTO query_charts VALUES ('food_poisoning_location_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '衛生福利部食品藥物管理署', '雙北食品中毒攝食場所分佈', '近 5 年雙北食品中毒依攝食場所分類，含自宅、供膳之營業場所、學校、辦公場所、其他。', '辨識中毒事件高發場所，作為餐飲衛生稽查與民眾教育依據', NULL, NULL, NOW(), NOW(), 'two_d', '
   SELECT x_axis, data FROM (VALUES
     (''供膳之營業場所'', 412),
     (''自宅'',           221),
     (''學校'',            64),
     (''辦公場所'',        49),
     (''其他'',            89)
   ) t(x_axis, data)
   ', NULL, 'metrotaipei');

INSERT INTO query_charts VALUES ('food_poisoning_trend_by_cause_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '衛生福利部食品藥物管理署', '雙北食品中毒年度×致病原因', '近 5 年雙北食品中毒案件依年度與致病原因雙維度分布。', '同時觀察主因類別在時間上的消長變化，輔助長期食品政策制定', NULL, NULL, NOW(), NOW(), 'time', '
   SELECT x_axis, y_axis, data FROM (VALUES
     (''2020-12-31''::timestamptz,''細菌性'',  68),
     (''2021-12-31''::timestamptz,''細菌性'',  72),
     (''2022-12-31''::timestamptz,''細菌性'',  84),
     (''2023-12-31''::timestamptz,''細菌性'',  88),
     (''2024-12-31''::timestamptz,''細菌性'',  90),
     (''2020-12-31''::timestamptz,''病毒性'',  28),
     (''2021-12-31''::timestamptz,''病毒性'',  31),
     (''2022-12-31''::timestamptz,''病毒性'',  39),
     (''2023-12-31''::timestamptz,''病毒性'',  42),
     (''2024-12-31''::timestamptz,''病毒性'',  46),
     (''2020-12-31''::timestamptz,''化學性'',  9),
     (''2021-12-31''::timestamptz,''化學性'',  10),
     (''2022-12-31''::timestamptz,''化學性'',  11),
     (''2023-12-31''::timestamptz,''化學性'',  12),
     (''2024-12-31''::timestamptz,''化學性'',  12),
     (''2020-12-31''::timestamptz,''天然毒素'',6),
     (''2021-12-31''::timestamptz,''天然毒素'',7),
     (''2022-12-31''::timestamptz,''天然毒素'',8),
     (''2023-12-31''::timestamptz,''天然毒素'',8),
     (''2024-12-31''::timestamptz,''天然毒素'',9),
     (''2020-12-31''::timestamptz,''不明'',    22),
     (''2021-12-31''::timestamptz,''不明'',    25),
     (''2022-12-31''::timestamptz,''不明'',    33),
     (''2023-12-31''::timestamptz,''不明'',    37),
     (''2024-12-31''::timestamptz,''不明'',    38)
   ) t(x_axis, y_axis, data) ORDER BY x_axis, y_axis
   ', NULL, 'metrotaipei');

INSERT INTO query_charts VALUES ('food_poisoning_trend_by_cause_metrotaipei', NULL, NULL, NULL, 'static', NULL, NULL, 'day', '臺北市政府衛生局', '臺北市食品中毒年度×致病原因', '近 5 年臺北市食品中毒案件依年度與致病原因雙維度分布。', '同時觀察臺北市致病類別變化', NULL, NULL, NOW(), NOW(), 'time', '
   SELECT x_axis, y_axis, data FROM (VALUES
     (''2020-12-31''::timestamptz,''細菌性'',  19),
     (''2021-12-31''::timestamptz,''細菌性'',  22),
     (''2022-12-31''::timestamptz,''細菌性'',  25),
     (''2023-12-31''::timestamptz,''細菌性'',  26),
     (''2024-12-31''::timestamptz,''細菌性'',  26),
     (''2020-12-31''::timestamptz,''病毒性'',   9),
     (''2021-12-31''::timestamptz,''病毒性'',  10),
     (''2022-12-31''::timestamptz,''病毒性'',  13),
     (''2023-12-31''::timestamptz,''病毒性'',  14),
     (''2024-12-31''::timestamptz,''病毒性'',  16),
     (''2020-12-31''::timestamptz,''化學性'',   3),
     (''2021-12-31''::timestamptz,''化學性'',   4),
     (''2022-12-31''::timestamptz,''化學性'',   5),
     (''2023-12-31''::timestamptz,''化學性'',   5),
     (''2024-12-31''::timestamptz,''化學性'',   5),
     (''2020-12-31''::timestamptz,''天然毒素'', 2),
     (''2021-12-31''::timestamptz,''天然毒素'', 2),
     (''2022-12-31''::timestamptz,''天然毒素'', 2),
     (''2023-12-31''::timestamptz,''天然毒素'', 2),
     (''2024-12-31''::timestamptz,''天然毒素'', 3),
     (''2020-12-31''::timestamptz,''不明'',     7),
     (''2021-12-31''::timestamptz,''不明'',     9),
     (''2022-12-31''::timestamptz,''不明'',    11),
     (''2023-12-31''::timestamptz,''不明'',    12),
     (''2024-12-31''::timestamptz,''不明'',    12)
   ) t(x_axis, y_axis, data) ORDER BY x_axis, y_axis
   ', NULL, 'taipei');

-- ----------------------------------------------------------------------------
-- 4. dashboards（雙北食安儀表板）
--    components 陣列用 SELECT 動態取 id，避免硬寫 223-226 撞夥伴環境
-- ----------------------------------------------------------------------------
INSERT INTO dashboards (index, name, components, icon, created_at, updated_at)
SELECT
  'food-safety-metrotaipei',
  '雙北食安儀表板',
  ARRAY(
    SELECT id FROM components
    WHERE index IN (
      'food_poisoning_trend_metrotaipei',
      'food_poisoning_cause_metrotaipei',
      'food_poisoning_location_metrotaipei',
      'food_poisoning_trend_by_cause_metrotaipei'
    )
    ORDER BY id
  ),
  'restaurant',
  NOW(),
  NOW()
ON CONFLICT (index) DO UPDATE
  SET name       = EXCLUDED.name,
      components = EXCLUDED.components,
      icon       = EXCLUDED.icon,
      updated_at = NOW();

-- ----------------------------------------------------------------------------
-- 5. dashboard_groups（掛到 group 'metrotaipei'）
-- ----------------------------------------------------------------------------
INSERT INTO dashboard_groups (dashboard_id, group_id)
SELECT d.id, g.id
FROM dashboards d, groups g
WHERE d.index = 'food-safety-metrotaipei'
  AND g.name  = 'metrotaipei'
ON CONFLICT (dashboard_id, group_id) DO NOTHING;

COMMIT;

-- ==========================================================================
-- 驗證查詢
-- ==========================================================================
-- SELECT index, name, components, icon FROM dashboards WHERE index = 'food-safety-metrotaipei';
-- SELECT count(*) FROM query_charts WHERE index LIKE 'food_poisoning_%_metrotaipei';  -- 應為 7
-- SELECT c.id, c.index, c.name, cc.types FROM components c
--   LEFT JOIN component_charts cc USING (index)
--   WHERE c.index LIKE 'food_poisoning_%_metrotaipei' ORDER BY c.id;  -- 應為 4
-- ==========================================================================
