-- ==============================================================================
-- 專案：雙北空氣品質監測站 - 資料表與模擬數據
-- 執行資料庫：dashboard
-- ==============================================================================

-- 1. 建立資料表 (符合 PostGIS 與 DE 規格)
CREATE TABLE IF NOT EXISTS public.moenv_air_quality (
    id SERIAL PRIMARY KEY,
    site_name VARCHAR(50),
    district VARCHAR(50),
    county VARCHAR(50),
    aqi INTEGER,
    status VARCHAR(50),
    wkb_geometry geometry(Point, 4326),
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS moenv_air_quality_geom_idx ON public.moenv_air_quality USING GIST (wkb_geometry);

-- 2. 清除舊數據並插入 6 筆雙北模擬數據 (包含行政區欄位以支援行政圖)
TRUNCATE public.moenv_air_quality;

INSERT INTO public.moenv_air_quality (site_name, district, county, aqi, status, wkb_geometry)
VALUES 
('萬華', '萬華區', '臺北市', 25, '良好', ST_GeomFromText('POINT(121.507972 25.046503)', 4326)),
('大同', '大同區', '臺北市', 32, '良好', ST_GeomFromText('POINT(121.513311 25.063292)', 4326)),
('松山', '松山區', '臺北市', 15, '良好', ST_GeomFromText('POINT(121.578611 25.05)', 4326)),
('板橋', '板橋區', '新北市', 55, '普通', ST_GeomFromText('POINT(121.457972 25.011333)', 4326)),
('土城', '土城區', '新北市', 42, '良好', ST_GeomFromText('POINT(121.451861 24.982528)', 4326)),
('三重', '三重區', '新北市', 68, '普通', ST_GeomFromText('POINT(121.493806 25.072611)', 4326));
