-- Migration: 新增 7 個靜態 GeoJSON 地圖組件
-- 組件清單:
--   air_station_map_taipei      臺北市空氣品質監測站
--   labor_services_taipei       臺北市勞工服務據點
--   labor_services_metrotaipei  雙北勞工服務據點
--   museums_taipei              臺北市博物館
--   museums_metrotaipei         雙北博物館
--   shelters_taipei             臺北市防空避難所
--   shelters_metrotaipei        雙北防空避難所
--
-- 前置條件:
--   GeoJSON 檔案已存在於 Taipei-City-Dashboard-FE/public/mapData/
--   dashboard `map-layers-taipei` (index) 與 `map-layers-metrotaipei` 已存在
--
-- 執行方式:
--   psql -d dashboardmanager -f migrations/add_7_static_map_layers.sql
--
-- 回滾方式:
--   psql -d dashboardmanager -f migrations/rollback_7_static_map_layers.sql

BEGIN;

DO $mig$
DECLARE
  v_max_map_id     BIGINT;

  -- component_maps IDs (預先分配 7 個連續 ID)
  v_air_tp_map     BIGINT;
  v_labor_tp_map   BIGINT;
  v_labor_mt_map   BIGINT;
  v_museum_tp_map  BIGINT;
  v_museum_mt_map  BIGINT;
  v_shelter_tp_map BIGINT;
  v_shelter_mt_map BIGINT;

  -- components IDs
  v_air_tp_cid     BIGINT;
  v_labor_tp_cid   BIGINT;
  v_labor_mt_cid   BIGINT;
  v_museum_tp_cid  BIGINT;
  v_museum_mt_cid  BIGINT;
  v_shelter_tp_cid BIGINT;
  v_shelter_mt_cid BIGINT;

BEGIN

  -- ========================================================
  -- 0. 分配 7 個連續的 component_maps ID（避免並發衝突需在交易中完成）
  -- ========================================================
  SELECT COALESCE(MAX(id), 100) + 1 INTO v_max_map_id FROM public.component_maps;
  v_air_tp_map     := v_max_map_id;
  v_labor_tp_map   := v_max_map_id + 1;
  v_labor_mt_map   := v_max_map_id + 2;
  v_museum_tp_map  := v_max_map_id + 3;
  v_museum_mt_map  := v_max_map_id + 4;
  v_shelter_tp_map := v_max_map_id + 5;
  v_shelter_mt_map := v_max_map_id + 6;

  RAISE NOTICE 'Allocated component_maps IDs: %, %, %, %, %, %, %',
    v_air_tp_map, v_labor_tp_map, v_labor_mt_map,
    v_museum_tp_map, v_museum_mt_map,
    v_shelter_tp_map, v_shelter_mt_map;

  -- ========================================================
  -- 1. 新增 / 更新 components 表
  -- ========================================================

  -- air_station_map_taipei
  SELECT id INTO v_air_tp_cid
    FROM public.components WHERE index = 'air_station_map_taipei' LIMIT 1;
  IF v_air_tp_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('air_station_map_taipei', '臺北市空氣品質監測站')
    RETURNING id INTO v_air_tp_cid;
  ELSE
    UPDATE public.components SET name = '臺北市空氣品質監測站' WHERE id = v_air_tp_cid;
  END IF;

  -- labor_services_taipei
  SELECT id INTO v_labor_tp_cid
    FROM public.components WHERE index = 'labor_services_taipei' LIMIT 1;
  IF v_labor_tp_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('labor_services_taipei', '臺北市勞工服務據點')
    RETURNING id INTO v_labor_tp_cid;
  ELSE
    UPDATE public.components SET name = '臺北市勞工服務據點' WHERE id = v_labor_tp_cid;
  END IF;

  -- labor_services_metrotaipei
  SELECT id INTO v_labor_mt_cid
    FROM public.components WHERE index = 'labor_services_metrotaipei' LIMIT 1;
  IF v_labor_mt_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('labor_services_metrotaipei', '雙北勞工服務據點')
    RETURNING id INTO v_labor_mt_cid;
  ELSE
    UPDATE public.components SET name = '雙北勞工服務據點' WHERE id = v_labor_mt_cid;
  END IF;

  -- museums_taipei
  SELECT id INTO v_museum_tp_cid
    FROM public.components WHERE index = 'museums_taipei' LIMIT 1;
  IF v_museum_tp_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('museums_taipei', '臺北市博物館')
    RETURNING id INTO v_museum_tp_cid;
  ELSE
    UPDATE public.components SET name = '臺北市博物館' WHERE id = v_museum_tp_cid;
  END IF;

  -- museums_metrotaipei
  SELECT id INTO v_museum_mt_cid
    FROM public.components WHERE index = 'museums_metrotaipei' LIMIT 1;
  IF v_museum_mt_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('museums_metrotaipei', '雙北博物館')
    RETURNING id INTO v_museum_mt_cid;
  ELSE
    UPDATE public.components SET name = '雙北博物館' WHERE id = v_museum_mt_cid;
  END IF;

  -- shelters_taipei
  SELECT id INTO v_shelter_tp_cid
    FROM public.components WHERE index = 'shelters_taipei' LIMIT 1;
  IF v_shelter_tp_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('shelters_taipei', '臺北市防空避難所')
    RETURNING id INTO v_shelter_tp_cid;
  ELSE
    UPDATE public.components SET name = '臺北市防空避難所' WHERE id = v_shelter_tp_cid;
  END IF;

  -- shelters_metrotaipei
  SELECT id INTO v_shelter_mt_cid
    FROM public.components WHERE index = 'shelters_metrotaipei' LIMIT 1;
  IF v_shelter_mt_cid IS NULL THEN
    INSERT INTO public.components (index, name)
    VALUES ('shelters_metrotaipei', '雙北防空避難所')
    RETURNING id INTO v_shelter_mt_cid;
  ELSE
    UPDATE public.components SET name = '雙北防空避難所' WHERE id = v_shelter_mt_cid;
  END IF;

  RAISE NOTICE 'Component IDs: air_tp=%, labor_tp=%, labor_mt=%, museum_tp=%, museum_mt=%, shelter_tp=%, shelter_mt=%',
    v_air_tp_cid, v_labor_tp_cid, v_labor_mt_cid,
    v_museum_tp_cid, v_museum_mt_cid,
    v_shelter_tp_cid, v_shelter_mt_cid;

  -- ========================================================
  -- 2. 更新 component_charts
  -- ========================================================
  DELETE FROM public.component_charts WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  INSERT INTO public.component_charts (index, color, types, unit) VALUES
    -- AQI 6 級色階（環境部官方配色）
    ('air_station_map_taipei',
     '{#00e400,#ffff00,#ff7e00,#ff0000,#8f3f97,#7e0023}',
     '{MapLegend}', NULL),
    -- 勞工服務 5 類別色
    ('labor_services_taipei',
     '{#FF7043,#26A69A,#42A5F5,#AB47BC,#FFA726}',
     '{MapLegend}', NULL),
    ('labor_services_metrotaipei',
     '{#FF7043,#26A69A,#42A5F5,#AB47BC,#FFA726}',
     '{MapLegend}', NULL),
    -- 博物館 4 類型色
    ('museums_taipei',
     '{#E67E22,#7F8C8D,#27AE60,#9B59B6}',
     '{MapLegend}', NULL),
    ('museums_metrotaipei',
     '{#E67E22,#7F8C8D,#27AE60,#9B59B6}',
     '{MapLegend}', NULL),
    -- 避難所 單色
    ('shelters_taipei',
     '{#3498DB}',
     '{MapLegend}', NULL),
    ('shelters_metrotaipei',
     '{#3498DB}',
     '{MapLegend}', NULL);

  -- ========================================================
  -- 3. 新增 / 更新 component_maps
  -- ========================================================
  -- 清除舊紀錄（若重複執行）
  DELETE FROM public.component_maps WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- air_station_map_taipei（AQI step color）
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_air_tp_map,
    'air_station_map_taipei',
    '空品測站',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":8,"circle-color":["step",["get","aqi"],"#00e400",51,"#ffff00",101,"#ff7e00",151,"#ff0000",201,"#8f3f97",301,"#7e0023"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"site_name","name":"測站名稱"},{"key":"aqi","name":"AQI"},{"key":"status","name":"空氣品質狀態"},{"key":"county","name":"所屬縣市"},{"key":"pollutant","name":"主要污染物"},{"key":"pm_2point5_ug_m3","name":"PM2.5 (μg/m³)"},{"key":"data_time","name":"更新時間"}]$prop$::json
  );

  -- labor_services_taipei（依 category_label match 上色）
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_labor_tp_map,
    'labor_services_taipei',
    '勞工服務據點',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":7,"circle-color":["match",["get","category_label"],"庇護工場","#FF7043","就業服務","#26A69A","勞動行政","#42A5F5","勞工權益保障","#AB47BC","職業訓練","#FFA726","#808080"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"category_label","name":"服務類型"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"url","name":"網址"}]$prop$::json
  );

  -- labor_services_metrotaipei
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_labor_mt_map,
    'labor_services_metrotaipei',
    '勞工服務據點',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":7,"circle-color":["match",["get","category_label"],"庇護工場","#FF7043","就業服務","#26A69A","勞動行政","#42A5F5","勞工權益保障","#AB47BC","職業訓練","#FFA726","#808080"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"category_label","name":"服務類型"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"city","name":"城市"}]$prop$::json
  );

  -- museums_taipei（依 type match 上色）
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_museum_tp_map,
    'museums_taipei',
    '博物館',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":7,"circle-color":["match",["get","type"],"歷史與人文","#E67E22","綜合與其他","#7F8C8D","自然與科學","#27AE60","藝術與工藝","#9B59B6","#808080"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"name_en","name":"英文名稱"},{"key":"type","name":"類型"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"website","name":"網站"}]$prop$::json
  );

  -- museums_metrotaipei
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_museum_mt_map,
    'museums_metrotaipei',
    '博物館',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":7,"circle-color":["match",["get","type"],"歷史與人文","#E67E22","綜合與其他","#7F8C8D","自然與科學","#27AE60","藝術與工藝","#9B59B6","#808080"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"name_en","name":"英文名稱"},{"key":"type","name":"類型"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"city_name","name":"城市"}]$prop$::json
  );

  -- shelters_taipei（單色圓點）
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_shelter_tp_map,
    'shelters_taipei',
    '防空避難所',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":6,"circle-color":"#3498DB","circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"address","name":"地址"},{"key":"district","name":"行政區"},{"key":"capacity","name":"容量（人）"},{"key":"indoor","name":"室內"},{"key":"outdoor","name":"室外"},{"key":"disaster_types","name":"適用災害"},{"key":"vulnerable_friendly","name":"弱勢友善"}]$prop$::json
  );

  -- shelters_metrotaipei
  INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
  VALUES (
    v_shelter_mt_map,
    'shelters_metrotaipei',
    '防空避難所',
    'circle',
    'geojson',
    NULL, NULL,
    $paint${"circle-radius":6,"circle-color":"#3498DB","circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
    $prop$[{"key":"name","name":"名稱"},{"key":"address","name":"地址"},{"key":"district","name":"行政區"},{"key":"capacity","name":"容量（人）"},{"key":"indoor","name":"室內"},{"key":"outdoor","name":"室外"},{"key":"disaster_types","name":"適用災害"},{"key":"city","name":"城市"}]$prop$::json
  );

  -- ========================================================
  -- 4. 新增 / 更新 query_charts
  -- ========================================================
  DELETE FROM public.query_charts WHERE index IN (
    'air_station_map_taipei',
    'labor_services_taipei',    'labor_services_metrotaipei',
    'museums_taipei',            'museums_metrotaipei',
    'shelters_taipei',           'shelters_metrotaipei'
  );

  -- air_station_map_taipei (taipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'air_station_map_taipei', NULL, ARRAY[v_air_tp_map], '{}',
    'static', NULL, 0, NULL,
    '環境部 監測資訊司',
    '臺北市空氣品質測站即時點位與 AQI。',
    '此地圖組件呈現臺北市所有環境部空氣品質監測站的即時資料。圓點顏色依 AQI 值套用官方 6 級色階（良好綠、普通黃、對敏感族群不良橘、對所有族群不良紅、非常不良紫、危害褐），可一眼掌握各區空氣品質分布。點擊測站圓點可展開彈窗顯示詳細資訊。',
    '適合用於即時監控臺北市空氣品質熱區，查看哪些行政區 AQI 超標，或在空品不佳時段提供民眾外出決策參考。',
    '{https://data.moenv.gov.tw/dataset/detail/aqx_p_432}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['良好','普通','對敏感族群不良','對所有族群不良','非常不良','危害']) AS name, 'circle' AS type$q$,
    NULL, 'taipei'
  );

  -- labor_services_taipei (taipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'labor_services_taipei', NULL, ARRAY[v_labor_tp_map], '{}',
    'static', NULL, 0, NULL,
    '臺北市政府勞動局',
    '臺北市勞工服務據點分布，涵蓋庇護工場、就業服務、勞動行政、勞工權益保障與職業訓練。',
    '此地圖顯示臺北市各類勞工服務據點的分布，依服務類型以不同顏色標示，協助市民快速找到最近的服務資源。',
    '適合用於查詢最近的就業服務站或職業訓練機構，亦可評估各行政區服務覆蓋率。',
    '{https://data.taipei/}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['庇護工場','就業服務','勞動行政','勞工權益保障','職業訓練']) AS name, 'circle' AS type$q$,
    NULL, 'taipei'
  );

  -- labor_services_metrotaipei (metrotaipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'labor_services_metrotaipei', NULL, ARRAY[v_labor_mt_map], '{}',
    'static', NULL, 0, NULL,
    '雙北市政府勞動局',
    '雙北勞工服務據點分布，涵蓋庇護工場、就業服務、勞動行政、勞工權益保障與職業訓練。',
    '此地圖顯示臺北市與新北市各類勞工服務據點的分布，依服務類型以不同顏色標示。',
    '適合查詢雙北地區最近的就業服務站或職業訓練機構，或跨城市比較服務佈建密度。',
    '{https://data.taipei/,https://data.ntpc.gov.tw/}',
    '{doit,ntpc}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['庇護工場','就業服務','勞動行政','勞工權益保障','職業訓練']) AS name, 'circle' AS type$q$,
    NULL, 'metrotaipei'
  );

  -- museums_taipei (taipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'museums_taipei', NULL, ARRAY[v_museum_tp_map], '{}',
    'static', NULL, 0, NULL,
    '臺北市政府文化局',
    '臺北市博物館分布，依歷史與人文、自然與科學、藝術與工藝及綜合類型標色。',
    '此地圖呈現臺北市各類博物館的分布，以類型顏色標示，方便市民或遊客規劃文化參觀路線。',
    '適合文化旅遊規劃、安排校外教學路線，或評估各行政區文化設施覆蓋情形。',
    '{https://data.taipei/}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['歷史與人文','綜合與其他','自然與科學','藝術與工藝']) AS name, 'circle' AS type$q$,
    NULL, 'taipei'
  );

  -- museums_metrotaipei (metrotaipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'museums_metrotaipei', NULL, ARRAY[v_museum_mt_map], '{}',
    'static', NULL, 0, NULL,
    '雙北市政府文化局',
    '雙北博物館分布，依歷史與人文、自然與科學、藝術與工藝及綜合類型標色。',
    '此地圖呈現臺北市與新北市各類博物館的分布。',
    '適合文化旅遊規劃，比較雙北博物館資源分布，為政策規劃提供文化設施覆蓋參考。',
    '{https://data.taipei/,https://data.ntpc.gov.tw/}',
    '{doit,ntpc}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['歷史與人文','綜合與其他','自然與科學','藝術與工藝']) AS name, 'circle' AS type$q$,
    NULL, 'metrotaipei'
  );

  -- shelters_taipei (taipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'shelters_taipei', NULL, ARRAY[v_shelter_tp_map], '{}',
    'static', NULL, 0, NULL,
    '臺北市政府消防局',
    '臺北市防空避難所分布，標示各避難場所位置、容量及適用災害類型。',
    '此地圖顯示臺北市所有登記之防空避難所位置，提供名稱、地址、容量、室內外空間、適用災害與弱勢友善資訊。',
    '適合緊急應變規劃、查詢附近避難所，或評估各行政區避難容量與空間分布。',
    '{https://data.taipei/}',
    '{doit}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['防空避難所']) AS name, 'circle' AS type$q$,
    NULL, 'taipei'
  );

  -- shelters_metrotaipei (metrotaipei)
  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'shelters_metrotaipei', NULL, ARRAY[v_shelter_mt_map], '{}',
    'static', NULL, 0, NULL,
    '雙北市政府消防局',
    '雙北防空避難所分布，標示各避難場所位置、容量及適用災害類型。',
    '此地圖顯示臺北市與新北市所有登記之防空避難所位置。',
    '適合緊急應變規劃或跨城市比較避難容量分布。',
    '{https://data.taipei/,https://data.ntpc.gov.tw/}',
    '{doit,ntpc}',
    NOW(), NOW(),
    'map_legend',
    $q$SELECT unnest(array['防空避難所']) AS name, 'circle' AS type$q$,
    NULL, 'metrotaipei'
  );

  -- ========================================================
  -- 5. 掛載組件至既有 dashboards
  --    taipei variants  → map-layers-taipei
  --    metrotaipei variants → map-layers-metrotaipei
  -- ========================================================

  -- taipei: air_station_map_taipei
  UPDATE public.dashboards
  SET components = array_append(components, v_air_tp_cid), updated_at = NOW()
  WHERE index = 'map-layers-taipei'
    AND NOT (v_air_tp_cid = ANY(components));

  -- taipei: labor_services_taipei
  UPDATE public.dashboards
  SET components = array_append(components, v_labor_tp_cid), updated_at = NOW()
  WHERE index = 'map-layers-taipei'
    AND NOT (v_labor_tp_cid = ANY(components));

  -- taipei: museums_taipei
  UPDATE public.dashboards
  SET components = array_append(components, v_museum_tp_cid), updated_at = NOW()
  WHERE index = 'map-layers-taipei'
    AND NOT (v_museum_tp_cid = ANY(components));

  -- taipei: shelters_taipei
  UPDATE public.dashboards
  SET components = array_append(components, v_shelter_tp_cid), updated_at = NOW()
  WHERE index = 'map-layers-taipei'
    AND NOT (v_shelter_tp_cid = ANY(components));

  -- metrotaipei: labor_services_metrotaipei
  UPDATE public.dashboards
  SET components = array_append(components, v_labor_mt_cid), updated_at = NOW()
  WHERE index = 'map-layers-metrotaipei'
    AND NOT (v_labor_mt_cid = ANY(components));

  -- metrotaipei: museums_metrotaipei
  UPDATE public.dashboards
  SET components = array_append(components, v_museum_mt_cid), updated_at = NOW()
  WHERE index = 'map-layers-metrotaipei'
    AND NOT (v_museum_mt_cid = ANY(components));

  -- metrotaipei: shelters_metrotaipei
  UPDATE public.dashboards
  SET components = array_append(components, v_shelter_mt_cid), updated_at = NOW()
  WHERE index = 'map-layers-metrotaipei'
    AND NOT (v_shelter_mt_cid = ANY(components));

  RAISE NOTICE '完成！7 個地圖組件已建立並掛載至儀表板。';

END $mig$;

COMMIT;

-- ========================================================
-- 驗證查詢
-- ========================================================
SELECT
  c.id   AS component_id,
  c.index,
  c.name,
  qc.city,
  qc.map_config_ids,
  cm.type AS map_type,
  cm.source
FROM public.components c
JOIN public.query_charts qc ON qc.index = c.index
JOIN public.component_maps cm ON cm.id = ANY(qc.map_config_ids)
WHERE c.index IN (
  'air_station_map_taipei',
  'labor_services_taipei',    'labor_services_metrotaipei',
  'museums_taipei',            'museums_metrotaipei',
  'shelters_taipei',           'shelters_metrotaipei'
)
ORDER BY c.index, qc.city;

SELECT index, name, array_length(components, 1) AS num_components, components
FROM public.dashboards
WHERE index IN ('map-layers-taipei', 'map-layers-metrotaipei');
