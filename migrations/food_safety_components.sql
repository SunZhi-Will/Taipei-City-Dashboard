-- =============================================================
-- Migration: Food Safety Components Rebuild
-- Target DB: postgres-manager / dashboardmanager
--
-- Rebuilds 7 food safety components and one dashboard:
--   taipei_imap_food
--   ntpc_food_factory
--   food_poisoning_trend
--   food_poisoning_cause
--   food_poisoning_food
--   food_poisoning_place
--   wholesale_pesticide_inspection
--
-- Data tables are loaded separately into postgres-data / dashboard via:
--   psql -U postgres -d dashboard < migrations/food_safety_data.sql
-- =============================================================

BEGIN;

DO $mig$
DECLARE
	v_taipei_food_map_id BIGINT;
	v_ntpc_factory_map_id BIGINT;
	v_taipei_wholesale_map_id BIGINT;
	v_wholesale_map_id BIGINT;

	v_taipei_food_cid BIGINT;
	v_ntpc_factory_cid BIGINT;
	v_trend_cid BIGINT;
	v_cause_cid BIGINT;
	v_food_cid BIGINT;
	v_place_cid BIGINT;
	v_taipei_wholesale_cid BIGINT;
	v_wholesale_cid BIGINT;

	v_map_layers_taipei_id BIGINT;
	v_map_layers_metrotaipei_id BIGINT;
	v_dashboard_id BIGINT;
	v_dashboard_taipei_id BIGINT;
BEGIN
	-- Keep SERIAL sequence in sync for idempotent reruns on restored DBs.
	PERFORM setval(
		'public.component_maps_id_seq',
		COALESCE((SELECT MAX(id) FROM public.component_maps), 1),
		true
	);

	-- component_maps: taipei_imap_food
	SELECT id INTO v_taipei_food_map_id
	FROM public.component_maps
	WHERE index = 'taipei_imap_food'
	LIMIT 1;

	IF v_taipei_food_map_id IS NULL THEN
		INSERT INTO public.component_maps (index, title, type, source, size, icon, paint, property)
		VALUES (
			'taipei_imap_food',
			'臺北市食品抽驗結果',
			'circle',
			'geojson',
			NULL,
			NULL,
			'{"circle-color":["match",["get","result"],"A1","#4CAF50","A2","#8BC34A","A3","#FF9800","#F44336"],"circle-radius":5,"circle-opacity":0.82}'::json,
			'[{"key":"name","name":"店家名稱"},{"key":"district","name":"行政區"},{"key":"result","name":"抽驗結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		)
		RETURNING id INTO v_taipei_food_map_id;
	ELSE
		UPDATE public.component_maps
		SET title = '臺北市食品抽驗結果',
			type = 'circle',
			source = 'geojson',
			size = NULL,
			icon = NULL,
			paint = '{"circle-color":["match",["get","result"],"A1","#4CAF50","A2","#8BC34A","A3","#FF9800","#F44336"],"circle-radius":5,"circle-opacity":0.82}'::json,
			property = '[{"key":"name","name":"店家名稱"},{"key":"district","name":"行政區"},{"key":"result","name":"抽驗結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		WHERE id = v_taipei_food_map_id;
	END IF;

	-- component_maps: ntpc_food_factory
	SELECT id INTO v_ntpc_factory_map_id
	FROM public.component_maps
	WHERE index = 'ntpc_food_factory'
	LIMIT 1;

	IF v_ntpc_factory_map_id IS NULL THEN
		INSERT INTO public.component_maps (index, title, type, source, size, icon, paint, property)
		VALUES (
			'ntpc_food_factory',
			'新北市食品工廠',
			'circle',
			'geojson',
			NULL,
			'factory',
			'{"circle-color":"#FF7043","circle-radius":5,"circle-opacity":0.78}'::json,
			'[{"key":"name","name":"工廠名稱"},{"key":"address","name":"地址"},{"key":"reg_no","name":"登記號"},{"key":"tax_id","name":"統一編號"}]'::json
		)
		RETURNING id INTO v_ntpc_factory_map_id;
	ELSE
		UPDATE public.component_maps
		SET title = '新北市食品工廠',
			type = 'circle',
			source = 'geojson',
			size = NULL,
			icon = 'factory',
			paint = '{"circle-color":"#FF7043","circle-radius":5,"circle-opacity":0.78}'::json,
			property = '[{"key":"name","name":"工廠名稱"},{"key":"address","name":"地址"},{"key":"reg_no","name":"登記號"},{"key":"tax_id","name":"統一編號"}]'::json
		WHERE id = v_ntpc_factory_map_id;
	END IF;

	-- component_maps: wholesale_pesticide_inspection
	SELECT id INTO v_taipei_wholesale_map_id
	FROM public.component_maps
	WHERE index = 'wholesale_pesticide_inspection_taipei'
	LIMIT 1;

	IF v_taipei_wholesale_map_id IS NULL THEN
		INSERT INTO public.component_maps (index, title, type, source, size, icon, paint, property)
		VALUES (
			'wholesale_pesticide_inspection_taipei',
			'臺北批發市場農藥殘留檢驗',
			'circle',
			'geojson',
			NULL,
			NULL,
			'{"circle-color":["match",["get","result"],"合格","#2ECC71","#E74C3C"],"circle-radius":5,"circle-opacity":0.85,"circle-stroke-color":"#ffffff","circle-stroke-width":0.8}'::json,
			'[{"key":"market","name":"市場"},{"key":"product_name","name":"品項"},{"key":"result","name":"結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		)
		RETURNING id INTO v_taipei_wholesale_map_id;
	ELSE
		UPDATE public.component_maps
		SET title = '臺北批發市場農藥殘留檢驗',
			type = 'circle',
			source = 'geojson',
			size = NULL,
			icon = NULL,
			paint = '{"circle-color":["match",["get","result"],"合格","#2ECC71","#E74C3C"],"circle-radius":5,"circle-opacity":0.85,"circle-stroke-color":"#ffffff","circle-stroke-width":0.8}'::json,
			property = '[{"key":"market","name":"市場"},{"key":"product_name","name":"品項"},{"key":"result","name":"結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		WHERE id = v_taipei_wholesale_map_id;
	END IF;

	-- component_maps: wholesale_pesticide_inspection
	SELECT id INTO v_wholesale_map_id
	FROM public.component_maps
	WHERE index = 'wholesale_pesticide_inspection'
	LIMIT 1;

	IF v_wholesale_map_id IS NULL THEN
		INSERT INTO public.component_maps (index, title, type, source, size, icon, paint, property)
		VALUES (
			'wholesale_pesticide_inspection',
			'雙北批發市場農藥殘留檢驗',
			'circle',
			'geojson',
			NULL,
			NULL,
			'{"circle-color":["match",["get","result"],"合格","#2ECC71","#E74C3C"],"circle-radius":5,"circle-opacity":0.85,"circle-stroke-color":"#ffffff","circle-stroke-width":0.8}'::json,
			'[{"key":"market","name":"市場"},{"key":"product_name","name":"品項"},{"key":"result","name":"結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		)
		RETURNING id INTO v_wholesale_map_id;
	ELSE
		UPDATE public.component_maps
		SET title = '雙北批發市場農藥殘留檢驗',
			type = 'circle',
			source = 'geojson',
			size = NULL,
			icon = NULL,
			paint = '{"circle-color":["match",["get","result"],"合格","#2ECC71","#E74C3C"],"circle-radius":5,"circle-opacity":0.85,"circle-stroke-color":"#ffffff","circle-stroke-width":0.8}'::json,
			property = '[{"key":"market","name":"市場"},{"key":"product_name","name":"品項"},{"key":"result","name":"結果"},{"key":"month","name":"月份"},{"_animate":true,"interval_ms":1500}]'::json
		WHERE id = v_wholesale_map_id;
	END IF;

	-- components
	INSERT INTO public.components (index, name)
	VALUES
		('taipei_imap_food', '食品業者衛生稽查地圖'),
		('ntpc_food_factory', '新北市食品工廠清冊'),
		('food_poisoning_trend', '食品中毒月度統計'),
		('food_poisoning_cause', '致病原因分布'),
		('food_poisoning_food', '可能中毒食品分布'),
		('food_poisoning_place', '食品中毒攝食場所'),
		('wholesale_pesticide_inspection', '蔬果農藥殘留檢驗')
	ON CONFLICT (index) DO UPDATE
	SET name = EXCLUDED.name;

	SELECT id INTO v_taipei_food_cid FROM public.components WHERE index = 'taipei_imap_food';
	SELECT id INTO v_ntpc_factory_cid FROM public.components WHERE index = 'ntpc_food_factory';
	SELECT id INTO v_trend_cid FROM public.components WHERE index = 'food_poisoning_trend';
	SELECT id INTO v_cause_cid FROM public.components WHERE index = 'food_poisoning_cause';
	SELECT id INTO v_food_cid FROM public.components WHERE index = 'food_poisoning_food';
	SELECT id INTO v_place_cid FROM public.components WHERE index = 'food_poisoning_place';
	SELECT id INTO v_taipei_wholesale_cid FROM public.components WHERE index = 'wholesale_pesticide_inspection_taipei';
	SELECT id INTO v_wholesale_cid FROM public.components WHERE index = 'wholesale_pesticide_inspection';

	-- component_charts
	INSERT INTO public.component_charts (index, color, types, unit)
	VALUES
		('taipei_imap_food', '{#39D98A,#F5C542,#FF6B6B}', '{DonutChart,AnimatedColumnChart}', '件'),
		('ntpc_food_factory', '{#FF7043}', '{MapLegend}', '家'),
		('food_poisoning_trend', '{#EF5350,#42A5F5,#66BB6A,#FFA726,#AB47BC,#26C6DA,#8D6E63,#EC407A,#7E57C2,#29B6F6,#9CCC65,#FF7043}', '{AnimatedColumnChart,TimelineSeparateChart}', '件'),
		('food_poisoning_cause', '{#FF6B6B,#FF8C42,#FFD166,#8BD448,#2EC4B6,#4D96FF,#9B5DE5,#F15BB5,#8D99AE,#A98467}', '{DonutChart,BarChart}', '件'),
		('food_poisoning_food', '{#4D96FF,#3A86FF,#FF6B6B,#F4A261,#FFD166,#8BD448,#2EC4B6,#9B5DE5,#F15BB5,#8D99AE}', '{DonutChart,BarChart}', '件'),
		('food_poisoning_place', '{#4D96FF,#39D98A,#F5C542,#FF8C42,#FF6B6B,#9B5DE5,#2EC4B6,#A98467,#8D99AE,#90BE6D,#FFB703,#6C757D}', '{DonutChart,BarChart}', '件'),
		('wholesale_pesticide_inspection', '{#39D98A,#F5C542,#FF6B6B}', '{DonutChart,BarChart}', '件')
	ON CONFLICT (index) DO UPDATE
	SET color = EXCLUDED.color,
		types = EXCLUDED.types,
		unit = EXCLUDED.unit;

	-- query_charts: remove old rows to keep reruns deterministic
	DELETE FROM public.query_charts
	WHERE index IN (
		'taipei_imap_food',
		'ntpc_food_factory',
		'food_poisoning_trend',
		'food_poisoning_cause',
		'food_poisoning_food',
		'food_poisoning_place',
		'wholesale_pesticide_inspection'
	);

	-- taipei_imap_food
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'taipei_imap_food',
		'{"range":["fiveyear_ago"],"color":["#4CAF50","#FF9800","#F44336"],"unit":"件"}'::json,
		ARRAY[v_taipei_food_map_id::integer],
		'{"mode":"byParam","byParam":{"xParam":"result"}}'::json,
		'static',
		NULL,
		1,
		'month',
		'臺北市衛生局',
		'臺北市食品抽驗結果，依月份與結果類型呈現。',
		'使用 taipei_imap_food 資料表動態統計抽驗結果，將 A1/A2 合併為合格，A3 視為正在複查，其他結果視為不合格；並提供月份動畫時序資料。',
		'適用於監控臺北市食品抽驗風險與月份變化。',
		'{https://imap.taipei.gov.tw/}'::text[],
		'{doit}'::text[],
		NOW(),
		NOW(),
		'two_d',
		$q$SELECT CASE
					 WHEN result IN ('A1', 'A2') THEN '合格'
					 WHEN result = 'A3' THEN '正在複查'
					 ELSE '不合格'
				 END AS x_axis,
				 COUNT(*)::float AS data
			FROM public.taipei_imap_food
		   GROUP BY 1
		   ORDER BY CASE
						WHEN CASE
								 WHEN result IN ('A1', 'A2') THEN '合格'
								 WHEN result = 'A3' THEN '正在複查'
								 ELSE '不合格'
							 END = '合格' THEN 1
						WHEN CASE
								 WHEN result IN ('A1', 'A2') THEN '合格'
								 WHEN result = 'A3' THEN '正在複查'
								 ELSE '不合格'
							 END = '正在複查' THEN 2
						ELSE 3
					END$q$,
		$q$SELECT (month || '-01')::timestamptz AS x_axis,
				 CASE
					 WHEN result IN ('A1', 'A2') THEN '合格'
					 WHEN result = 'A3' THEN '正在複查'
					 ELSE '不合格'
				 END AS y_axis,
				 COUNT(*)::int AS data
			FROM public.taipei_imap_food
		   GROUP BY 1, 2
		   ORDER BY 1,
					MIN(CASE
						WHEN result IN ('A1', 'A2') THEN 1
						WHEN result = 'A3' THEN 2
						ELSE 3
					END)$q$,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- ntpc_food_factory
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'ntpc_food_factory',
		NULL,
		ARRAY[v_ntpc_factory_map_id::integer],
		'{}'::json,
		'static',
		NULL,
		0,
		NULL,
		'新北市政府衛生局',
		'新北市食品工廠空間分布。',
		'直接統計 ntpc_food_factory 資料表總筆數，並搭配工廠點位地圖。',
		'適用於查看新北市食品製造工廠整體規模與分布。',
		'{https://data.ntpc.gov.tw/}'::text[],
		'{ntpc}'::text[],
		NOW(),
		NOW(),
		'map_legend',
		$q$SELECT '新北市食品工廠' AS name,
				 'circle' AS type,
				 'factory' AS icon,
				 COUNT(*)::float AS value
			FROM public.ntpc_food_factory$q$,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- food_poisoning_trend
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'food_poisoning_trend',
		NULL,
		NULL,
		'{}'::json,
		'static',
		NULL,
		1,
		'year',
		'衛福部食藥署',
		'食品中毒月別趨勢。',
		'由 food_poisoning_trend 資料表動態產生月份時間序列。',
		'適用於查看食品中毒案件的長期月份變化。',
		'{https://data.fda.gov.tw/}'::text[],
		'{mohw}'::text[],
		NOW(),
		NOW(),
		'time',
		$q$SELECT (year::text || '-' || LPAD(month::text, 2, '0') || '-01')::timestamptz AS x_axis,
				 LPAD(month::text, 2, '0') || '月' AS y_axis,
				 cases::float AS data
			FROM public.food_poisoning_trend
		   ORDER BY year, month$q$,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- food_poisoning_cause
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'food_poisoning_cause',
		NULL,
		NULL,
		'{}'::json,
		'static',
		NULL,
		1,
		'year',
		'衛福部食藥署',
		'食品中毒病因物質分布。',
		'讀取最新年度的 food_poisoning_cause 分布。',
		'適用於辨識當前主要食品中毒病因。',
		'{https://data.fda.gov.tw/}'::text[],
		'{mohw}'::text[],
		NOW(),
		NOW(),
		'two_d',
		$q$SELECT cause AS x_axis,
				 cases::float AS data
			FROM public.food_poisoning_cause
		   WHERE year = (SELECT MAX(year) FROM public.food_poisoning_cause)
		   ORDER BY cases DESC, cause$q$,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- food_poisoning_food
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'food_poisoning_food',
		NULL,
		NULL,
		'{}'::json,
		'static',
		NULL,
		1,
		'year',
		'衛福部食藥署',
		'食品中毒原因食品分布。',
		'讀取最新年度的 food_poisoning_food 分布。',
		'適用於辨識當前高風險食品類型。',
		'{https://data.fda.gov.tw/}'::text[],
		'{mohw}'::text[],
		NOW(),
		NOW(),
		'two_d',
		$q$SELECT food_type AS x_axis,
				 cases::float AS data
			FROM public.food_poisoning_food
		   WHERE year = (SELECT MAX(year) FROM public.food_poisoning_food)
		   ORDER BY cases DESC, food_type$q$,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- food_poisoning_place
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'food_poisoning_place',
		NULL,
		NULL,
		'{}'::json,
		'static',
		NULL,
		1,
		'year',
		'衛福部食藥署',
		'食品中毒攝食場所分布。',
		'讀取最新年度的 food_poisoning_place 分布。',
		'適用於辨識當前高風險用餐場景。',
		'{https://data.fda.gov.tw/}'::text[],
		'{mohw}'::text[],
		NOW(),
		NOW(),
		'two_d',
		$q$SELECT place AS x_axis,
				 cases::float AS data
			FROM public.food_poisoning_place
		   WHERE year = (SELECT MAX(year) FROM public.food_poisoning_place)
		   ORDER BY cases DESC, place$q$,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);

	-- wholesale_pesticide_inspection (taipei & metrotaipei)
	INSERT INTO public.query_charts (
		index, history_config, map_config_ids, map_filter,
		time_from, time_to, update_freq, update_freq_unit,
		source, short_desc, long_desc, use_case,
		links, contributors, created_at, updated_at,
		query_type, query_chart, query_history, city
	)
	SELECT
		'wholesale_pesticide_inspection',
		NULL,
		ARRAY[CASE WHEN city_name = 'taipei' THEN v_taipei_wholesale_map_id ELSE v_wholesale_map_id END::integer],
		'{"mode":"byParam","byParam":{"xParam":"result"}}'::json,
		'static',
		NULL,
		1,
		'day',
		CASE WHEN city_name = 'taipei' THEN '臺北農產運銷公司' ELSE '臺北農產運銷公司 / 新北市果菜運銷公司' END,
		CASE WHEN city_name = 'taipei' THEN '臺北批發市場農藥殘留檢驗結果。' ELSE '雙北批發市場農藥殘留檢驗結果。' END,
		'統計批發市場資料，將非「合格」結果統一視為不合格。',
		'適用於檢視批發市場蔬果農藥殘留風險。',
		CASE WHEN city_name = 'taipei' THEN '{https://www.tapmc.com.tw/}'::text[] ELSE '{https://www.tapmc.com.tw/,https://www.ntpm.com.tw/}'::text[] END,
		'{doit}'::text[],
		NOW(),
		NOW(),
		'two_d',
		CASE WHEN city_name = 'taipei' 
			 THEN $q$SELECT CASE WHEN result = '合格' THEN '合格' ELSE '不合格' END AS x_axis, COUNT(*)::float AS data FROM public.wholesale_pesticide_inspection WHERE market IN ('第一批發市場', '第二批發市場') GROUP BY 1 ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)$q$
			 ELSE $q$SELECT CASE WHEN result = '合格' THEN '合格' ELSE '不合格' END AS x_axis, COUNT(*)::float AS data FROM public.wholesale_pesticide_inspection GROUP BY 1 ORDER BY MIN(CASE WHEN result = '合格' THEN 1 ELSE 2 END)$q$
		END,
		NULL,
		city_name
	FROM (VALUES ('taipei'::text), ('metrotaipei'::text)) AS cities(city_name);


	SELECT id INTO v_map_layers_taipei_id
	FROM public.dashboards
	WHERE index = 'map-layers-taipei'
	LIMIT 1;

	IF v_map_layers_taipei_id IS NULL THEN
		INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
		VALUES (
			'map-layers-taipei',
			'圖資資訊',
			ARRAY[]::integer[],
			'public',
			NOW(),
			NOW()
		)
		RETURNING id INTO v_map_layers_taipei_id;
	END IF;

	INSERT INTO public.dashboard_groups (dashboard_id, group_id)
	VALUES (v_map_layers_taipei_id, 2)
	ON CONFLICT DO NOTHING;

	SELECT id INTO v_map_layers_metrotaipei_id
	FROM public.dashboards
	WHERE index = 'map-layers-metrotaipei'
	LIMIT 1;

	IF v_map_layers_metrotaipei_id IS NULL THEN
		INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
		VALUES (
			'map-layers-metrotaipei',
			'圖資資訊',
			ARRAY[]::integer[],
			'public',
			NOW(),
			NOW()
		)
		RETURNING id INTO v_map_layers_metrotaipei_id;
	END IF;

	INSERT INTO public.dashboard_groups (dashboard_id, group_id)
	VALUES (v_map_layers_metrotaipei_id, 3)
	ON CONFLICT DO NOTHING;

	-- taipei-only dashboard
	INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
	VALUES (
		'food_safety_taipei',
		'臺北食品安全',
		ARRAY[
			v_taipei_food_cid::integer,
			v_food_cid::integer,
			v_cause_cid::integer,
			v_trend_cid::integer,
			v_place_cid::integer,
			v_wholesale_cid::integer
		],
		'health_and_safety',
		NOW(),
		NOW()
	)
	ON CONFLICT (index) DO UPDATE
	SET name = EXCLUDED.name,
		components = EXCLUDED.components,
		icon = EXCLUDED.icon,
		updated_at = NOW()
	RETURNING id INTO v_dashboard_taipei_id;

	DELETE FROM public.dashboard_groups
	WHERE dashboard_id = v_dashboard_taipei_id
	  AND group_id IN (2, 3);

	INSERT INTO public.dashboard_groups (dashboard_id, group_id)
	VALUES (v_dashboard_taipei_id, 2)
	ON CONFLICT DO NOTHING;

	-- metrotaipei dashboard
	INSERT INTO public.dashboards (index, name, components, icon, updated_at, created_at)
	VALUES (
		'food_safety_tpe',
		'雙北食品安全',
		ARRAY[
			v_taipei_food_cid::integer,
			v_food_cid::integer,
			v_cause_cid::integer,
			v_trend_cid::integer,
			v_place_cid::integer,
			v_wholesale_cid::integer
		],
		'health_and_safety',
		NOW(),
		NOW()
	)
	ON CONFLICT (index) DO UPDATE
	SET name = EXCLUDED.name,
		components = EXCLUDED.components,
		icon = EXCLUDED.icon,
		updated_at = NOW()
	RETURNING id INTO v_dashboard_id;

	DELETE FROM public.dashboard_groups
	WHERE dashboard_id = v_dashboard_id
	  AND group_id IN (2, 3);

	INSERT INTO public.dashboard_groups (dashboard_id, group_id)
	VALUES (v_dashboard_id, 3)
	ON CONFLICT DO NOTHING;
END $mig$;

COMMIT;
