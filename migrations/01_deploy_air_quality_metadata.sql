-- ==============================================================================
-- 專案：雙北空氣品質監測站 - 完整部署腳本
-- 內容：包含組件元數據、圖表配置、及查詢邏輯
-- 執行資料庫：dashboardmanager
-- ==============================================================================

BEGIN;

DO $mig$
DECLARE
	v_component_id BIGINT;
	v_map_id BIGINT;
BEGIN
	SELECT id INTO v_component_id
	FROM public.components
	WHERE index = 'air_station_map_metrotaipei'
	ORDER BY id
	LIMIT 1;

	IF v_component_id IS NULL THEN
		INSERT INTO public.components (index, name)
		VALUES ('air_station_map_metrotaipei', '雙北空氣品質監測站')
		RETURNING id INTO v_component_id;
	ELSE
		UPDATE public.components
		SET name = '雙北空氣品質監測站'
		WHERE id = v_component_id;
	END IF;

	DELETE FROM public.component_charts
	WHERE index = 'air_station_map_metrotaipei';

	INSERT INTO public.component_charts (index, color, types, unit)
	VALUES (
		'air_station_map_metrotaipei',
		'{#00e400,#ffff00,#ff7e00,#ff0000,#8f3f97,#7e0023}',
		'{ColumnChart,DistrictChart}',
		'AQI'
	);

	SELECT id INTO v_map_id
	FROM public.component_maps
	WHERE index = 'air_station_map_metrotaipei'
	ORDER BY id
	LIMIT 1;

	IF v_map_id IS NULL THEN
		SELECT COALESCE(MAX(id), 0) + 1 INTO v_map_id
		FROM public.component_maps;

		INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
		VALUES (
			v_map_id,
			'air_station_map_metrotaipei',
			'空氣品質監測站',
			'circle',
			'geojson',
			NULL,
			NULL,
			'{"circle-color": ["step", ["get", "aqi"], "#00e400", 51, "#ffff00", 101, "#ff7e00", 151, "#ff0000", 201, "#8f3f97", 301, "#7e0023"], "circle-radius": 8, "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}'::json,
			'{"測站名稱": "name", "AQI": "aqi", "狀態": "status", "所屬縣市": "county"}'::json
		);
	ELSE
		UPDATE public.component_maps
		SET title = '空氣品質監測站',
				type = 'circle',
				source = 'geojson',
				size = NULL,
				icon = NULL,
				paint = '{"circle-color": ["step", ["get", "aqi"], "#00e400", 51, "#ffff00", 101, "#ff7e00", 151, "#ff0000", 201, "#8f3f97", 301, "#7e0023"], "circle-radius": 8, "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}'::json,
				property = '{"測站名稱": "name", "AQI": "aqi", "狀態": "status", "所屬縣市": "county"}'::json
		WHERE id = v_map_id;

		DELETE FROM public.component_maps
		WHERE index = 'air_station_map_metrotaipei'
			AND id <> v_map_id;
	END IF;

	DELETE FROM public.query_charts
	WHERE index = 'air_station_map_metrotaipei'
		AND city = 'metrotaipei';

	INSERT INTO public.query_charts (index, query_type, city, query_chart, map_config_ids)
	VALUES (
		'air_station_map_metrotaipei',
		'three_d',
		'metrotaipei',
		'SELECT district AS x_axis, county AS y_axis, aqi AS data, site_name AS name, aqi AS value, county AS type FROM public.moenv_air_quality ORDER BY county, aqi DESC',
		ARRAY[v_map_id]
	);
END $mig$;

COMMIT;
