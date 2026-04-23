-- ==============================================================================
-- 專案：雙北空氣品質監測站 - 完整部署腳本
-- 內容：包含組件元數據、圖表配置、及查詢邏輯
-- 執行資料庫：dashboardmanager
-- ==============================================================================

-- 1. 建立組件核心定義
INSERT INTO public.components (id, index, name, description)
VALUES (219, 'air_station_map_metrotaipei', '雙北空氣品質監測站', '顯示台北市與新北市即時空氣品質(AQI)監測站點與統計比較')
ON CONFLICT (index) DO NOTHING;

-- 2. 建立圖表配置 (支援行政圖與柱狀圖)
INSERT INTO public.component_charts (index, color, types, unit)
VALUES ('air_station_map_metrotaipei', '{#00e400,#ffff00,#ff7e00,#ff0000,#8f3f97,#7e0023}', '{ColumnChart,DistrictChart}', 'AQI')
ON CONFLICT (index) DO UPDATE 
SET types = EXCLUDED.types, unit = EXCLUDED.unit;

-- 3. 建立三維查詢邏輯 (X軸對應行政區名，用於行政圖上色)
INSERT INTO public.query_charts (index, query_type, city, query_chart, map_config_ids)
VALUES ('air_station_map_metrotaipei', 'three_d', 'metrotaipei', 
'SELECT district AS x_axis, county AS y_axis, aqi AS data, site_name AS name, aqi AS value, county AS type FROM public.moenv_air_quality ORDER BY county, aqi DESC', 
'{102}')
ON CONFLICT (index) DO UPDATE 
SET query_type = EXCLUDED.query_type, query_chart = EXCLUDED.query_chart;

-- 4. 建立地圖圖層配置
INSERT INTO public.component_maps (id, index, type, paint, layout, source, city, property, title)
VALUES (102, 'air_station_map_metrotaipei', 'circle', 
'{"circle-color": ["step", ["get", "aqi"], "#00e400", 51, "#ffff00", 101, "#ff7e00", 151, "#ff0000", 201, "#8f3f97", 301, "#7e0023"], "circle-radius": 8, "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}',
'{"visibility": "visible"}', 
'geojson', 'metrotaipei', 
'{"測站名稱": "name", "AQI": "aqi", "狀態": "status", "所屬縣市": "county"}', '空氣品質監測站')
ON CONFLICT (id) DO NOTHING;
