-- Migration: 註冊 air_station_map_metrotaipei 地圖組件
-- 資料來源：既有表 public.moenv_air_quality（由 DAG D050502 每小時更新）
-- 組件規格：docs/superpowers/specs/2026-04-23-air-station-map-design.md
-- 前置條件：moenv_air_quality 表存在且有資料
-- 執行方式（跨平台）：psql -d dashboardmanager -f air_station_map_metrotaipei.sql

BEGIN;

DO $mig$
DECLARE
  v_component_id  BIGINT;
  v_map_id        BIGINT;
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

  SELECT id INTO v_map_id
  FROM public.component_maps
  WHERE index = 'air_station_map_metrotaipei'
  ORDER BY id
  LIMIT 1;

  IF v_map_id IS NULL THEN
    SELECT COALESCE(MAX(id), 0) + 1 INTO v_map_id
    FROM public.component_maps;
  END IF;

  RAISE NOTICE '使用 component id=%, map id=%', v_component_id, v_map_id;

  -- 2) component_charts（6 級 AQI 色帶，環境部官方配色）
  DELETE FROM public.component_charts
  WHERE index = 'air_station_map_metrotaipei';

  INSERT INTO public.component_charts (index, color, types, unit) VALUES
    ('air_station_map_metrotaipei',
     '{#00e400,#ffff00,#ff7e00,#ff0000,#8f3f97,#7e0023}',
     '{ColumnChart,DistrictChart}',
     'AQI');

  -- 3) component_maps（circle + step expression 依 AQI 上色）
  IF EXISTS (
    SELECT 1
    FROM public.component_maps
    WHERE id = v_map_id
  ) THEN
    UPDATE public.component_maps
    SET index = 'air_station_map_metrotaipei',
        title = '空品測站',
        type = 'circle',
        source = 'geojson',
        size = NULL,
        icon = NULL,
        paint = $paint${"circle-radius":8,"circle-color":["step",["get","aqi"],"#00e400",51,"#ffff00",101,"#ff7e00",151,"#ff0000",201,"#8f3f97",301,"#7e0023"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
        property = $prop$[{"key":"site_name","name":"測站名稱"},{"key":"aqi","name":"AQI"},{"key":"status","name":"空氣品質狀態"},{"key":"district","name":"行政區"},{"key":"county","name":"所屬縣市"},{"key":"update_time","name":"更新時間"}]$prop$::json
    WHERE id = v_map_id;
  ELSE
    INSERT INTO public.component_maps
      (id, index, title, type, source, size, icon, paint, property)
    VALUES (
      v_map_id,
      'air_station_map_metrotaipei',
      '空品測站',
      'circle',
      'geojson',
      NULL,
      NULL,
      $paint${"circle-radius":8,"circle-color":["step",["get","aqi"],"#00e400",51,"#ffff00",101,"#ff7e00",151,"#ff0000",201,"#8f3f97",301,"#7e0023"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}$paint$::json,
      $prop$[{"key":"site_name","name":"測站名稱"},{"key":"aqi","name":"AQI"},{"key":"status","name":"空氣品質狀態"},{"key":"district","name":"行政區"},{"key":"county","name":"所屬縣市"},{"key":"update_time","name":"更新時間"}]$prop$::json
    );
  END IF;

  DELETE FROM public.component_maps
  WHERE index = 'air_station_map_metrotaipei'
    AND id <> v_map_id;

  -- 4) query_charts（三維資料供長條圖/行政圖使用，並綁定 map config）
  DELETE FROM public.query_charts
  WHERE index = 'air_station_map_metrotaipei'
    AND city = 'metrotaipei';

  INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    source, short_desc, long_desc, use_case,
    links, contributors,
    created_at, updated_at,
    query_type, query_chart, query_history, city
  ) VALUES (
    'air_station_map_metrotaipei',
    NULL,
    ARRAY[v_map_id],
    NULL,
    'current',
    NULL,
    1,
    'hour',
    '環境部 監測資訊司',
    '雙北空氣品質測站即時點位與 AQI 彈窗。',
    '此地圖組件呈現臺北市與新北市所有環境部空氣品質監測站的最新即時資料。每個測站以圓點顯示，圓點顏色依據該測站當前 AQI 值自動套用環境部官方 6 級色階（良好綠、普通黃、對敏感族群不良橘、對所有族群不良紅、非常不良紫、危害褐），使用者可一眼掌握雙北各區空氣品質分佈。點擊測站圓點可展開彈窗，顯示測站名稱、AQI 數值、空氣品質狀態文字、主要污染物、PM2.5 濃度與資料發布時間 6 項資訊。資料每小時由環境部 API 更新一次。',
    '適合用於即時監控雙北空氣品質熱區、比較不同行政區空品差異、或在空品不佳時段提供民眾外出決策參考。例如：紫爆日查看哪些行政區超標最嚴重、PM2.5 高時找出可能污染源、長期觀察特定測站的 AQI 變化趨勢。可搭配時序圖組件 air_quality_trend 做深入分析。',
    '{https://data.moenv.gov.tw/dataset/detail/aqx_p_432}',
    '{doit,ntpc}',
    NOW(),
    NOW(),
    'three_d',
    'SELECT district AS x_axis, county AS y_axis, aqi AS data, site_name AS name, aqi AS value, county AS type FROM public.moenv_air_quality ORDER BY county, aqi DESC',
    NULL,
    'metrotaipei'
  );

  RAISE NOTICE '✅ air_station_map_metrotaipei 4 筆 row 建立完成';
END $mig$;

COMMIT;
