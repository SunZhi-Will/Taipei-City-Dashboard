-- ==========================================================================
-- food_safety_3complete_partial.sql — 補上 3 個地圖類食安組件（C 路線）
--
-- 內容：從 food_safety_3complete_components.sql 截取「可執行」部分
--   - 跳過原檔 line 10-11 兩條斷掉的 component_maps INSERT
--   - 改用 sequence 自動分配 id，避免硬寫 id=2,5 撞到既有資料
--   - 用 ON CONFLICT (index) 處理重複
--
-- 涵蓋的 3 個 component（不含 illegal_food_ad）：
--   1. ntpc_food_factory          新北市食品工廠分布   (symbol map)
--   2. taipei_imap_food           食品業者衛生稽查地圖 (chart, 缺 component_map)
--   3. wholesale_pesticide_inspection  雙北蔬果農藥檢驗 (circle map)
--
-- 用法：
--   docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
--     < migrations/food_safety_3complete_partial.sql
--
-- 副作用：把這 3 個 component 加進 food-safety-metrotaipei dashboard 的
--        components 陣列，保留原本 4 個食物中毒。最終 7 個 component。
-- ==========================================================================

BEGIN;

-- 1. components（讓 sequence 自動分配 id；ON CONFLICT 用 index）
INSERT INTO components (index, name) VALUES
  ('ntpc_food_factory',              '新北市食品工廠分布'),
  ('taipei_imap_food',               '食品業者衛生稽查地圖'),
  ('wholesale_pesticide_inspection', '雙北蔬果農藥檢驗')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

-- 2. component_charts（外觀設定）
INSERT INTO component_charts (index, color, types, unit) VALUES
  ('ntpc_food_factory',
   ARRAY['#3498DB','#2980B9','#E74C3C','#C0392B','#F39C12']::varchar[],
   ARRAY['MapLegend']::varchar[],
   '家'),
  ('taipei_imap_food',
   ARRAY['#2ECC71','#F1C40F','#E74C3C']::varchar[],
   ARRAY['DonutChart']::varchar[],
   '家'),
  ('wholesale_pesticide_inspection',
   ARRAY['#2ECC71','#F1C40F','#E74C3C']::varchar[],
   ARRAY['DonutChart']::varchar[],
   '家')
ON CONFLICT (index) DO UPDATE
  SET color = EXCLUDED.color,
      types = EXCLUDED.types,
      unit  = EXCLUDED.unit;

-- 3. component_maps（沒 unique 約束，先 DELETE 同 index 再 INSERT）
--    只放 line 8-9 那 2 條完整的；line 10-11 斷掉的略過
DELETE FROM component_maps
 WHERE index IN ('ntpc_food_factory', 'taipei_imap_food', 'wholesale_pesticide_inspection');

-- ntpc_food_factory: symbol map（icon=factory）
INSERT INTO component_maps (index, title, type, source, size, icon, paint, property) VALUES
  ('ntpc_food_factory',
   '新北市食品工廠',
   'symbol',
   'geojson',
   NULL,
   'factory',
   '{}'::json,
   '[{"key":"name","name":"廠商名稱"},{"key":"address","name":"地址"},{"key":"reg_no","name":"登記號"},{"key":"tax_id","name":"統一編號"}]'::json);

-- wholesale_pesticide_inspection: circle map（合格綠 / 不合格紅，含月份動畫）
INSERT INTO component_maps (index, title, type, source, size, icon, paint, property) VALUES
  ('wholesale_pesticide_inspection',
   '雙北果菜批發市場',
   'circle',
   'geojson',
   NULL,
   NULL,
   '{"circle-color": ["match", ["get", "result"], "合格", "#2ECC71", "不合格", "#E74C3C", "#95A5A6"], "circle-radius": 5, "circle-opacity": 0.85, "circle-stroke-color": "#ffffff", "circle-stroke-width": 0.8}'::json,
   '[{"key": "market", "name": "市場"}, {"key": "product_name", "name": "品項"}, {"key": "result", "name": "結果"}, {"key": "month", "name": "月份"}, {"_animate": "month", "interval_ms": 1500}]'::json);

-- taipei_imap_food: circle map（重建被截斷的 line 11）
--   * A1優→B2缺失重大 綠→紅階梯（features.properties.result 為 A1/A2/A3...）
--   * 含 _animate 月份輪播（monthly_flat GeoJSON，36 個月可動畫）
INSERT INTO component_maps (index, title, type, source, size, icon, paint, property) VALUES
  ('taipei_imap_food',
   '臺北市食品業者衛生稽查',
   'circle',
   'geojson',
   NULL,
   NULL,
   '{"circle-color": ["match", ["get", "result"], "A1", "#27AE60", "A2", "#2ECC71", "A3", "#F1C40F", "B1", "#E67E22", "B2", "#E74C3C", "#95A5A6"], "circle-radius": 4, "circle-opacity": 0.85, "circle-stroke-color": "#ffffff", "circle-stroke-width": 0.6}'::json,
   '[{"key": "name", "name": "業者名稱"}, {"key": "address", "name": "地址"}, {"key": "district", "name": "行政區"}, {"key": "result", "name": "稽查結果"}, {"key": "reg_no", "name": "登記號"}, {"key": "month", "name": "月份"}, {"_animate": "month", "interval_ms": 1500}]'::json);

-- 4. query_charts（每個 component 必需的 metadata，否則 BE join 會回 500）
DELETE FROM query_charts WHERE index IN ('ntpc_food_factory','taipei_imap_food','wholesale_pesticide_inspection');

INSERT INTO query_charts (index, query_type, time_from, source, short_desc, long_desc, use_case, query_chart, city, created_at, updated_at)
VALUES (
  'ntpc_food_factory', 'map_legend', 'static', '新北市政府衛生局',
  '新北市食品工廠登記分布。',
  '新北市轄內所有經食品工廠登記之業者點位，含廠商名稱、地址與登記號。',
  '稽查、產業地理分布觀察、食品工廠密集區辨識。',
  E'SELECT ''食品工廠'' AS name, ''circle'' AS type, ''factory'' AS icon, COUNT(*)::float AS value FROM public.ntpc_food_factory',
  'metrotaipei', NOW(), NOW()
),
(
  'taipei_imap_food', 'two_d', 'static', '臺北市政府衛生局',
  '臺北市食品業者衛生稽查結果分布。',
  '依台北市 iMap 食品業者衛生稽查結果資料分組計數，呈現 A1/A2 等分級佔比。',
  '掌握臺北市食品業者稽查合格狀況。',
  E'SELECT result AS x_axis, COUNT(*) AS data FROM public.taipei_imap_food WHERE result IS NOT NULL GROUP BY result ORDER BY result',
  'metrotaipei', NOW(), NOW()
),
(
  'wholesale_pesticide_inspection', 'two_d', 'static', '臺北市/新北市批發市場',
  '雙北果菜批發市場農藥殘留檢驗結果分布。',
  '雙北市果菜批發市場每月農藥殘留抽驗，計算合格與不合格件數。',
  '辨識農藥殘留問題嚴重性、評估抽驗成效。',
  E'SELECT result AS x_axis, COUNT(*) AS data FROM public.wholesale_pesticide_inspection WHERE result IS NOT NULL GROUP BY result ORDER BY result',
  'metrotaipei', NOW(), NOW()
);

-- 5. 連結 query_charts.map_config_ids → component_maps.id（讓 API map_config 不為空）
UPDATE query_charts
   SET map_config_ids = ARRAY(SELECT id FROM component_maps WHERE index = 'ntpc_food_factory')
 WHERE index = 'ntpc_food_factory';

UPDATE query_charts
   SET map_config_ids = ARRAY(SELECT id FROM component_maps WHERE index = 'wholesale_pesticide_inspection')
 WHERE index = 'wholesale_pesticide_inspection';

UPDATE query_charts
   SET map_config_ids = ARRAY(SELECT id FROM component_maps WHERE index = 'taipei_imap_food')
 WHERE index = 'taipei_imap_food';

-- 5.5 台北版 query_charts（讓 food-safety dashboard ?city=taipei 也顯示這 3 個 component）
INSERT INTO query_charts (index, query_type, time_from, source, short_desc, long_desc, use_case, query_chart, map_config_ids, city, created_at, updated_at)
VALUES
  ('ntpc_food_factory', 'map_legend', 'static', '新北市政府衛生局',
   '新北市食品工廠登記分布（台北市無資料來源）',
   '本資料表僅含新北市食品工廠登記。台北市無相關資料。',
   '對照觀察用',
   E'SELECT ''食品工廠'' AS name, ''circle'' AS type, ''factory'' AS icon, COUNT(*)::float AS value FROM public.ntpc_food_factory WHERE address LIKE ''臺北市%''',
   ARRAY(SELECT id FROM component_maps WHERE index = 'ntpc_food_factory'),
   'taipei', NOW(), NOW()),

  ('taipei_imap_food', 'two_d', 'static', '臺北市政府衛生局',
   '臺北市食品業者衛生稽查結果分布',
   '依台北市 iMap 食品業者衛生稽查結果資料分組計數，A1/A2/A3/B1/B2 分級佔比。',
   '掌握臺北市食品業者稽查合格狀況',
   E'SELECT result AS x_axis, COUNT(*) AS data FROM public.taipei_imap_food WHERE result IS NOT NULL GROUP BY result ORDER BY result',
   ARRAY(SELECT id FROM component_maps WHERE index = 'taipei_imap_food'),
   'taipei', NOW(), NOW()),

  ('wholesale_pesticide_inspection', 'two_d', 'static', '臺北市政府',
   '臺北市果菜批發市場農藥殘留檢驗',
   '臺北第一/第二果菜批發市場每月農藥殘留抽驗，合格 vs 不合格件數。',
   '辨識臺北市場農藥殘留問題',
   E'SELECT result AS x_axis, COUNT(*) AS data FROM public.wholesale_pesticide_inspection WHERE result IS NOT NULL AND market IN (''第一批發市場'',''第二批發市場'') GROUP BY result ORDER BY result',
   ARRAY(SELECT id FROM component_maps WHERE index = 'wholesale_pesticide_inspection'),
   'taipei', NOW(), NOW());

-- 6. dashboard 「食安健康」7 components：單 index + 雙 group pattern
--    legacy 雙 index（food-safety-metrotaipei / food-safety-taipei）若存在會被清掉

DELETE FROM dashboard_groups
  WHERE dashboard_id IN (
    SELECT id FROM dashboards WHERE index IN ('food-safety-metrotaipei','food-safety-taipei')
  );
DELETE FROM dashboards
  WHERE index IN ('food-safety-metrotaipei','food-safety-taipei');

UPDATE dashboards
SET name       = '食安健康',
    components = ARRAY(
      SELECT id FROM components
       WHERE index IN (
         'food_poisoning_trend_metrotaipei',
         'food_poisoning_cause_metrotaipei',
         'food_poisoning_location_metrotaipei',
         'food_poisoning_trend_by_cause_metrotaipei',
         'ntpc_food_factory',
         'taipei_imap_food',
         'wholesale_pesticide_inspection'
       )
       ORDER BY id
    ),
    updated_at = NOW()
WHERE index = 'food-safety';

-- 若 food-safety 還沒被基礎 seed (food_safety_metrotaipei.sql) 建好，這裡也建
INSERT INTO dashboards (index, name, components, icon, created_at, updated_at)
SELECT
  'food-safety',
  '食安健康',
  ARRAY(
    SELECT id FROM components
     WHERE index IN (
       'food_poisoning_trend_metrotaipei',
       'food_poisoning_cause_metrotaipei',
       'food_poisoning_location_metrotaipei',
       'food_poisoning_trend_by_cause_metrotaipei',
       'ntpc_food_factory',
       'taipei_imap_food',
       'wholesale_pesticide_inspection'
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

-- 雙 group：同一 dashboard 掛在 taipei + metrotaipei
INSERT INTO dashboard_groups (dashboard_id, group_id)
SELECT d.id, g.id FROM dashboards d, groups g
WHERE d.index = 'food-safety'
  AND g.name IN ('taipei', 'metrotaipei')
ON CONFLICT (dashboard_id, group_id) DO NOTHING;

COMMIT;

-- ==========================================================================
-- 驗證
-- SELECT index, array_length(components, 1) AS cnt FROM dashboards
--   WHERE index = 'food-safety-metrotaipei';   -- 應為 7
-- SELECT index, type FROM component_maps WHERE index ~ 'food|ntpc|imap|pesticide';  -- 應 2 行
-- ==========================================================================
