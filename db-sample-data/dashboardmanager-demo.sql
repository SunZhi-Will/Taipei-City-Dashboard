--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: component_charts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.component_charts (index, color, types, unit) FROM stdin;
youbike_availability	{#9DC56E,#356340,#9DC56E}	{GuageChart,BarPercentChart}	輛
ebus_percent	{#9DC56E,#356340,#9DC56E}	{IconPercentChart,BarPercentChart}	輛
city_age_distribution	{#24B0DD,#56B96D,#F8CF58,#F5AD4A,#E170A6,#ED6A45,#AF4137,#10294A}	{DistrictChart,ColumnChart}	仟人
dependency_aging	{#67baca,#fbf3ac}	{ColumnLineChart,TimelineSeparateChart}	%
aging_kpi	{#F65658,#F49F36,#F5C860,#9AC17C,#4CB495,#569C9A,#60819C,#2F8AB1}	{TextUnitChart}	\N
aging_workforce_trend	{#24B0DD,#56B96D,#F8CF58,#F5AD4A,#E170A6,#ED6A45,#AF4137,#10294A}	{BarPercentChart,RadarChart,ColumnChart}	%
bike_network	{#a0b8e8,#b7ff98}	{DonutChart,BarChart}	公里
bike_map	{#a0b8e8,#b7ff98}	{MapLegend}	條
air_station_map_metrotaipei	{#00e400,#ffff00,#ff7e00,#ff0000,#8f3f97,#7e0023}	{MapLegend}	測站
museums_metrotaipei	{#e74c3c,#9b59b6,#2ecc71,#f39c12}	{MapLegend}	處
shelters_metrotaipei	{#3498db,#e67e22}	{MapLegend}	處
labor_services_metrotaipei	{#3498db,#9b59b6,#e74c3c,#2ecc71,#f39c12}	{MapLegend}	處
food_poisoning_trend_metrotaipei	{#3498db,#e74c3c}	{BarChart}	件
food_poisoning_cause_metrotaipei	{#e74c3c,#9b59b6,#f39c12,#2ecc71,#95a5a6}	{DonutChart}	件
food_poisoning_location_metrotaipei	{#3498db,#e67e22,#1abc9c,#9b59b6,#95a5a6}	{ColumnChart}	件
food_poisoning_trend_by_cause_metrotaipei	{#e74c3c,#9b59b6,#f39c12,#2ecc71,#95a5a6}	{BarChart}	件
ntpc_food_factory	{#3498DB,#2980B9,#E74C3C,#C0392B,#F39C12}	{MapLegend}	家
taipei_imap_food	{#2ECC71,#F1C40F,#E74C3C}	{DonutChart}	家
wholesale_pesticide_inspection	{#2ECC71,#F1C40F,#E74C3C}	{DonutChart}	家
\.


--
-- Data for Name: component_maps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.component_maps (id, index, title, type, source, size, icon, paint, property) FROM stdin;
70	youbike_realtime	youbike站點	symbol	geojson	\N	youbike	{}	[{"key":"sna","name":"場站名稱"},{"key":"sno","name":"場站ID"},{"key":"available_return_bikes","name":"可還車位"},{"key":"available_rent_general_bikes","name":"剩餘車輛"}]
99	youbike_realtime_metrotaipei	youbike站點	symbol	geojson	\N	youbike	{}	[{"key":"sna","name":"場站名稱"},{"key":"sno","name":"場站ID"},{"key":"available_return_bikes","name":"可還車位"},{"key":"available_rent_general_bikes","name":"剩餘車輛"}]
100	bike_network_tpe	自行車路網	line	geojson	\N	\N	{"line-color":["match",["get","direction"],"雙向","#097138","單向","#007BFF","#808080"]}	[\r\n  {"key": "data_time", "name": "數據時間"},\r\n  {"key": "route_name", "name": "路線名稱"},\r\n  {"key": "city_code", "name": "城市代碼"},\r\n  {"key": "city", "name": "城市"},\r\n  {"key": "road_section_start", "name": "起點路段"},\r\n  {"key": "road_section_end", "name": "終點路段"},\r\n  {"key": "direction", "name": "方向"},\r\n  {"key": "cycling_length", "name": "自行車道長度"},\r\n  {"key": "finished_time", "name": "完工時間"},\r\n  {"key": "update_time", "name": "更新時間"}\r\n]
101	bike_network_metrotaipei	自行車路網	line	geojson	\N	\N	{"line-color":["match",["get","direction"],"雙向","#097138","單向","#007BFF","#808080"]}	[\r\n  {"key": "data_time", "name": "數據時間"},\r\n  {"key": "route_name", "name": "路線名稱"},\r\n  {"key": "city_code", "name": "城市代碼"},\r\n  {"key": "city", "name": "城市"},\r\n  {"key": "road_section_start", "name": "起點路段"},\r\n  {"key": "road_section_end", "name": "終點路段"},\r\n  {"key": "direction", "name": "方向"},\r\n  {"key": "cycling_length", "name": "自行車道長度"},\r\n  {"key": "finished_time", "name": "完工時間"},\r\n  {"key": "update_time", "name": "更新時間"}\r\n]
102	air_station_map_metrotaipei	空品測站	circle	geojson	\N	\N	{"circle-color": ["step", ["get", "aqi"], "#00e400", 51, "#ffff00", 101, "#ff7e00", 151, "#ff0000", 201, "#8f3f97", 301, "#7e0023"], "circle-radius": 8, "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key": "site_name", "name": "測站名稱"}, {"key": "aqi", "name": "AQI"}, {"key": "status", "name": "空氣品質狀態"}, {"key": "pollutant", "name": "主要污染物"}, {"key": "pm_2point5_ug_m3", "name": "PM2.5 (μg/m³)"}, {"key": "data_time", "name": "發布時間"}]
5	air_station_map_taipei	空品測站	circle	geojson	\N	\N	{"circle-color": ["step", ["get", "aqi"], "#00e400", 51, "#ffff00", 101, "#ff7e00", 151, "#ff0000", 201, "#8f3f97", 301, "#7e0023"], "circle-radius": 8, "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key": "site_name", "name": "測站名稱"}, {"key": "aqi", "name": "AQI"}, {"key": "status", "name": "空氣品質狀態"}, {"key": "pollutant", "name": "主要污染物"}, {"key": "pm_2point5_ug_m3", "name": "PM2.5 (μg/m³)"}, {"key": "data_time", "name": "發布時間"}]
3	museums_metrotaipei	雙北博物館	circle	geojson	\N	triangle_white	{"circle-radius": 6, "circle-color": ["match", ["get", "type"], "歷史與人文", "#e74c3c", "藝術與工藝", "#9b59b6", "自然與科學", "#2ecc71", "綜合與其他", "#f39c12", "#888888"], "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key":"name","name":"館名"},{"key":"type","name":"類別"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"website","name":"官網"},{"key":"city_name","name":"縣市"}]
6	museums_taipei	雙北博物館	circle	geojson	\N	triangle_white	{"circle-radius": 6, "circle-color": ["match", ["get", "type"], "歷史與人文", "#e74c3c", "藝術與工藝", "#9b59b6", "自然與科學", "#2ecc71", "綜合與其他", "#f39c12", "#888888"], "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key":"name","name":"館名"},{"key":"type","name":"類別"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"website","name":"官網"},{"key":"city_name","name":"縣市"}]
4	shelters_metrotaipei	雙北避難收容所	circle	geojson	\N	triangle_green	{"circle-radius": 5, "circle-color": ["match", ["get", "city"], "taipei", "#3498db", "new_taipei", "#e67e22", "#888888"], "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key":"name","name":"設施名稱"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"capacity","name":"預計收容人數"},{"key":"disaster_types","name":"適用災害"},{"key":"manager_phone","name":"管理人電話"}]
7	shelters_taipei	雙北避難收容所	circle	geojson	\N	triangle_green	{"circle-radius": 5, "circle-color": ["match", ["get", "city"], "taipei", "#3498db", "new_taipei", "#e67e22", "#888888"], "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}	[{"key":"name","name":"設施名稱"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"capacity","name":"預計收容人數"},{"key":"disaster_types","name":"適用災害"},{"key":"manager_phone","name":"管理人電話"}]
10	labor_services_metrotaipei	雙北勞動服務據點	circle	geojson	\N		{"circle-radius":5,"circle-color":["match",["get","category_label"],"就業服務","#3498db","職業訓練","#9b59b6","庇護工場","#e74c3c","勞工權益保障","#2ecc71","勞動行政","#f39c12","#cccccc"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}	[{"key":"name","name":"據點名稱"},{"key":"category_label","name":"類別"},{"key":"type","name":"細分類"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"url","name":"網址"}]
11	labor_services_taipei	雙北勞動服務據點	circle	geojson	\N		{"circle-radius":5,"circle-color":["match",["get","category_label"],"就業服務","#3498db","職業訓練","#9b59b6","庇護工場","#e74c3c","勞工權益保障","#2ecc71","勞動行政","#f39c12","#cccccc"],"circle-stroke-width":1,"circle-stroke-color":"#ffffff"}	[{"key":"name","name":"據點名稱"},{"key":"category_label","name":"類別"},{"key":"type","name":"細分類"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"},{"key":"phone","name":"電話"},{"key":"url","name":"網址"}]
19	ntpc_food_factory	新北市食品工廠	symbol	geojson	\N	factory	{}	[{"key":"name","name":"廠商名稱"},{"key":"address","name":"地址"},{"key":"reg_no","name":"登記號"},{"key":"tax_id","name":"統一編號"}]
20	wholesale_pesticide_inspection	雙北果菜批發市場	circle	geojson	\N	\N	{"circle-color": ["match", ["get", "result"], "合格", "#2ECC71", "不合格", "#E74C3C", "#95A5A6"], "circle-radius": 5, "circle-opacity": 0.85, "circle-stroke-color": "#ffffff", "circle-stroke-width": 0.8}	[{"key": "market", "name": "市場"}, {"key": "product_name", "name": "品項"}, {"key": "result", "name": "結果"}, {"key": "month", "name": "月份"}, {"_animate": "month", "interval_ms": 1500}]
21	taipei_imap_food	臺北市食品業者衛生稽查	circle	geojson	\N	\N	{"circle-color": ["match", ["get", "result"], "A1", "#27AE60", "A2", "#2ECC71", "A3", "#F1C40F", "B1", "#E67E22", "B2", "#E74C3C", "#95A5A6"], "circle-radius": 4, "circle-opacity": 0.85, "circle-stroke-color": "#ffffff", "circle-stroke-width": 0.6}	[{"key": "name", "name": "業者名稱"}, {"key": "address", "name": "地址"}, {"key": "district", "name": "行政區"}, {"key": "result", "name": "稽查結果"}, {"key": "reg_no", "name": "登記號"}, {"key": "month", "name": "月份"}, {"_animate": "month", "interval_ms": 1500}]
\.


--
-- Data for Name: components; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.components (id, index, name) FROM stdin;
60	youbike_availability	YouBike使用情況
213	bike_network	自行車道路統計資料
212	ebus_percent	電動巴士比例
214	dependency_aging	扶養比及老化指數
216	city_age_distribution	全市年齡分區
218	aging_kpi	長照指標
215	aging_workforce_trend	高齡就業人口之年增結構
217	bike_map	自行車道路網圖資
219	museums_metrotaipei	雙北博物館
220	shelters_metrotaipei	雙北避難收容所
221	air_station_map_metrotaipei	雙北空氣品質監測站
222	labor_services_metrotaipei	雙北勞動服務據點
223	food_poisoning_trend_metrotaipei	雙北食品中毒案件年度趨勢
224	food_poisoning_cause_metrotaipei	雙北食品中毒致病原因分佈
225	food_poisoning_location_metrotaipei	雙北食品中毒攝食場所分佈
226	food_poisoning_trend_by_cause_metrotaipei	雙北食品中毒原因×年度
9	ntpc_food_factory	新北市食品工廠分布
10	taipei_imap_food	食品業者衛生稽查地圖
11	wholesale_pesticide_inspection	雙北蔬果農藥檢驗
\.


--
-- Data for Name: contributors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contributors (id, user_id, user_name, image, link, identity, description, include, created_at, updated_at) FROM stdin;
1	doit	臺北市政府資訊局	doit.png	https://doit.gov.taipei/	\N	\N	f	2024-05-09 01:58:47.164185+00	2024-05-09 01:58:47.164185+00
2	ntpc	新北市政府資訊中心	ntpc.png	https://www.imc.ntpc.gov.tw/	\N	\N	f	2024-05-09 01:58:47.164185+00	2024-05-09 01:58:47.164185+00
\.


--
-- Data for Name: dashboards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dashboards (id, index, name, components, icon, updated_at, created_at) FROM stdin;
356	ltc_care_tpe	長照關懷	{214,215,216,218}	elderly	2025-02-26 08:43:42.86017+00	2024-03-21 09:38:37.66+00
355	ltc_care_newtpe	長照關懷	{214,215,216,218}	elderly	2025-02-27 06:42:21.705931+00	2024-03-21 09:38:37.66+00
358	practical_transportation_newtpe	務實交通	{60,212,213}	directions_car	2025-03-12 08:00:38.75842+00	2024-03-21 09:38:37.66+00
1	09a25cd9cb7d	收藏組件	\N	favorite	2025-03-14 07:34:22.247753+00	2025-03-14 07:34:22.247753+00
2	3245d9eace5f	我的新儀表板	{215,218,216,213,212,214,60,146}	star	2025-03-14 14:55:11.732116+00	2025-03-14 14:55:11.732116+00
360	da2c7bba8a3d	收藏組件	\N	favorite	2026-04-22 00:17:08.460423+00	2026-04-22 00:17:08.460423+00
106	map-layers-taipei	圖資資訊	{217,219,220,221,222}	public	2026-05-01 00:58:17.176211+00	2024-03-21 10:04:24.928533+00
359	map-layers-metrotaipei	圖資資訊	{217,219,220,221,222}	public	2026-05-01 00:58:17.176211+00	2024-03-21 10:04:24.928533+00
361	food-safety-metrotaipei	雙北食安儀表板	{9,10,11,223,224,225,226}	restaurant	2026-05-02 18:07:09.303168+00	2026-05-01 12:13:57.010624+00
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.groups (id, name, is_personal, create_by) FROM stdin;
1	public	f	\N
2	taipei	f	\N
3	metrotaipei	f	\N
4	user: 1's personal group	t	1
\.


--
-- Data for Name: dashboard_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dashboard_groups (dashboard_id, group_id) FROM stdin;
106	2
356	2
355	3
359	3
358	3
360	4
361	3
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.issues (id, title, user_name, user_id, context, description, decision_desc, status, updated_by, created_at, updated_at) FROM stdin;
4	test	Drew	1	test	test	測試	不處理	doit	2024-03-15 07:33:39.695288+00	2024-07-26 06:37:55.038985+00
\.


--
-- Data for Name: query_charts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.query_charts (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit, source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at, query_type, query_chart, query_history, city) FROM stdin;
aging_kpi	\N	{}	{}	static	\N	0	\N	主計處	此圖顯示雙北長照關懷各項指標。	此圖表呈現雙北長照關懷相關指標，包括 扶老比、扶幼比、扶養比 及 老化指數。扶老比代表每百名勞動人口需扶養的老年人口數，扶幼比則是需扶養的兒童人口數，而扶養比則合計這兩者，反映整體社會負擔程度。老化指數則比較老年人口與兒童人口比例，顯示人口結構的高齡化趨勢。這些數據可用於評估長照需求，並規劃資源分配與政策方向，以因應人口老化帶來的挑戰。	在制定長照政策時，政府可運用 扶老比、扶幼比、扶養比 及 老化指數 來評估未來照護需求。例如，某城市發現扶老比上升且老化指數超過 100，代表老年人口已多於兒童，預示長照需求將持續增加。政府可據此增設長照機構、強化居家照護服務，並鼓勵社區共融計畫，以減輕勞動人口的扶養壓力，確保高齡者獲得適切照顧。	{https://data.taipei/dataset/detail?id=64c8a3a0-3b9a-4f49-a13a-fb1eb2ffa4b1,https://data.ntpc.gov.tw/datasets/8308ab58-62d1-424e-8314-24b65b7ab492}	{doit,ntpc}	2023-12-20 05:56:00+00	2024-06-12 06:02:41.642+00	three_d	select y_axis,icon ,round(avg(data))data  \r\nfrom(\r\nselect '扶老比' as y_axis, percent30 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '扶幼比' as y_axis, percent31 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '扶養比' as y_axis, percent32 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '老化指數' as y_axis, percent33 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '扶老比' as y_axis, avg(percent30) as data ,'%' as icon \r\nfrom public.city_age_distribution_newtaipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_newtaipei )  and 統計類型='計'\r\nunion all\r\nselect '扶幼比' as y_axis, avg(percent31) as data ,'%' as icon \r\nfrom public.city_age_distribution_newtaipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_newtaipei ) and 統計類型='計'\r\nunion all\r\nselect '扶養比' as y_axis, avg(percent32) as data ,'%' as icon \r\nfrom public.city_age_distribution_newtaipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_newtaipei )  and 統計類型='計'\r\nunion all\r\nselect '老化指數' as y_axis, avg(percent33) as data ,'%' as icon \r\nfrom public.city_age_distribution_newtaipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_newtaipei )  and 統計類型='計'\r\n)d\r\ngroup by y_axis,icon	\N	metrotaipei
aging_kpi	\N	{}	{}	static	\N	0	\N	主計處	此圖顯示臺北長照關懷各項指標。	此圖表呈現臺北長照關懷相關指標，包括 扶老比、扶幼比、扶養比 及 老化指數。扶老比代表每百名勞動人口需扶養的老年人口數，扶幼比則是需扶養的兒童人口數，而扶養比則合計這兩者，反映整體社會負擔程度。老化指數則比較老年人口與兒童人口比例，顯示人口結構的高齡化趨勢。這些數據可用於評估長照需求，並規劃資源分配與政策方向，以因應人口老化帶來的挑戰。	在制定長照政策時，政府可運用 扶老比、扶幼比、扶養比 及 老化指數 來評估未來照護需求。例如，某城市發現扶老比上升且老化指數超過 100，代表老年人口已多於兒童，預示長照需求將持續增加。政府可據此增設長照機構、強化居家照護服務，並鼓勵社區共融計畫，以減輕勞動人口的扶養壓力，確保高齡者獲得適切照顧。	{https://data.taipei/dataset/detail?id=64c8a3a0-3b9a-4f49-a13a-fb1eb2ffa4b1}	{doit}	2023-12-20 05:56:00+00	2024-06-12 06:02:41.642+00	three_d	select y_axis,icon ,round(avg(data))data  \r\nfrom(\r\nselect '扶老比' as y_axis, percent30 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '扶幼比' as y_axis, percent31 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '扶養比' as y_axis, percent32 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\nunion all\r\nselect '老化指數' as y_axis, percent33 as data ,'%' as icon \r\nfrom public.city_age_distribution_taipei \r\nwhere 年份= (select max(年份) from public.city_age_distribution_taipei ) and  區域別='總計' and 統計類型='計'\r\n)d\r\ngroup by y_axis,icon	\N	taipei
aging_workforce_trend	\N	\N	\N	static	\N	\N	\N	主計處	顯示雙北就業人口之年齡結構時間數列統計資料	雙北地區人口年齡分配按月別時間數列統計資料，記錄臺北市與新北市各年齡層人口數的月度變化，涵蓋從0歲至65歲以上等多個年齡區間。該資料反映雙北地區人口在不同年齡層之分布情形，具備連續性與時間性，可作為分析區域人口結構、行政規劃及社會資源配置的重要參考。透過長期追蹤，亦能協助了解人口構成在不同時間點的變化狀況與組成比例，有助於支持各項人口相關研究與實務應用。	適用於跨域分析或探討都市群體共通趨勢，涵蓋臺北市與新北市兩地，常見於區域整體發展、通勤流動、就業市場整合、住宅與交通規劃等議題。亦可用於比較兩市人口結構差異、公共資源分布或整合性施政評估。例如：雙北地區勞動參與率變化、雙北通勤族群結構分析、雙北教育資源均衡程度探討等。	{https://data.taipei/dataset/detail?id=df320c78-f66b-4504-92b4-cf2a2eb46f1b,https://data.ntpc.gov.tw/datasets/c285509a-7fb2-434f-8542-0b4986c337a8}	{doit,ntpc}	2024-11-28 05:56:00+00	2024-12-10 02:59:39.341+00	three_d	select x_axis,y_axis,round(avg(percentage)) as data\r\nfrom (select year as x_axis,'1.非高齡就業人口' as y_axis,sum(percentage) as percentage  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure not in ('就業人口','就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲','就業人口按年齡別/65歲以上')\r\ngroup by year \r\nunion all \r\nselect year as x_axis,'2.中高齡就業人口' as y_axis,percentage as data  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲')\r\nunion all \r\nselect year as x_axis,'3.高齡就業人口' as y_axis,percentage as data  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/65歲以上')\r\nunion all \r\nselect year as x_axis,'1.非高齡就業人口' as y_axis,sum(percentage) as data  from employment_age_structure_new_tpe\r\nwhere  gender ='總計' and age_structure not in ('就業人口','就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲','就業人口按年齡別/65歲以上')\r\ngroup by year \r\nunion all \r\nselect year as x_axis,'2.中高齡就業人口' as y_axis,percentage as data  from employment_age_structure_new_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲')\r\nunion all \r\nselect year as x_axis,'3.高齡就業人口' as y_axis,percentage as data  from employment_age_structure_new_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/65歲以上'))d\r\nwhere x_axis >'2016'\r\ngroup by x_axis,y_axis \r\norder by 1,2	\N	metrotaipei
aging_workforce_trend	\N	\N	\N	static	\N	\N	\N	主計處	顯示臺北就業人口之年齡結構時間數列統計資料	臺北市人口年齡分配按月別時間數列統計資料，提供各年齡層人口數的定期統計結果，依月別呈現，涵蓋從幼年、青壯年至高齡等不同年齡區間。此資料可作為觀察人口結構組成的重要依據，反映各年齡層在人口總數中的分布情形。透過持續的月別紀錄，可供相關單位進行人口結構分析、資源分配規劃及政策評估等多元應用。資料內容具體、連續，適合用於進行長期與跨時比較之研究分析。	適用於聚焦單一行政區之人口、就業、教育、社會福利、都市規劃等議題。多用於市政層級的政策分析、市內人口結構觀察、社會服務配置研究，以及針對臺北市特定區域（如中正區、大安區等）的細部分析。例如：臺北市高齡人口比例變化、臺北市各區幼兒園分布狀況等。	{https://data.taipei/dataset/detail?id=df320c78-f66b-4504-92b4-cf2a2eb46f1b}	{doit}	2024-11-28 05:56:00+00	2025-03-19 10:25:55.340887+00	three_d	select x_axis,y_axis,round(avg(percentage)) as data\r\nfrom (select year as x_axis,'1.非高齡就業人口' as y_axis,sum(percentage) as percentage  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure not in ('就業人口','就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲','就業人口按年齡別/65歲以上')\r\ngroup by year \r\nunion all \r\nselect year as x_axis,'2.中高齡就業人口' as y_axis,percentage as data  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/45-49歲','就業人口按年齡別/50-54歲','就業人口按年齡別/55-59歲','就業人口按年齡別/60-64歲')\r\nunion all \r\nselect year as x_axis,'3.高齡就業人口' as y_axis,percentage as data  from employment_age_structure_tpe\r\nwhere  gender ='總計' and age_structure  in ('就業人口按年齡別/65歲以上')\r\n)d\r\nwhere x_axis >'2016'\r\ngroup by x_axis,y_axis \r\norder by 1,2	\N	taipei
bike_map	\N	{100,101}	{}	static	\N	\N	\N	交通局交工處	顯示雙北當前自行車路網分布。	顯示雙北當前自行車路網分布。雙北擁有完善的自行車路網，主要包括河濱自行車道和市區自行車道。河濱自行車道沿淡水河、基隆河、新店溪和景美溪等河岸建設，提供連續且風景優美的騎行路線。市區自行車道則遍布於主要道路，如敦化南北路、成功路、承德路、松隆路、松德路、和平西路、民生東路、北安路、金湖路、八德路、大道路、光復南路和永吉路等，方便市民在城市中安全騎行。此外，雙北政府持續推動「自行車道願景計畫」，以串聯既有路網、銜接跨市及河濱自行車道，並優化現有自行車道，提升騎行環境的便利性與安全性。	使用於地圖分析、交通規劃與旅遊建議，雙北的自行車路網可與其他圖資套疊，提供更深入的洞察。透過將自行車道與人口密度、交通流量或公車捷運路線交叉比對，可優化城市規劃，提高自行車友善程度。對於旅遊應用，可將自行車道與景點、商圈、飯店位置結合，推薦最佳騎行路線，提升遊憩體驗。此外，政府與企業可藉由數據分析發掘需求熱點，進一步優化自行車基礎設施與共享單車系統。	{https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/Taipei?%24top=30&%24format=JSON,https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/NewTaipei?%24top=30&%24format=JSON}	{doit,ntpc}	2023-12-20 05:56:00+00	2024-01-11 06:26:02.069+00	map_legend	SELECT unnest(array['自行車路網']) as name, 'line' as type	\N	metrotaipei
bike_map	\N	{100}	{}	static	\N	\N	\N	交通局交工處	顯示臺北當前自行車路網分布。	顯示臺北市當前自行車路網分布。臺北市擁有完善的自行車路網，主要由河濱自行車道與市區自行車道組成。河濱自行車道沿淡水河、基隆河、新店溪與景美溪等河岸規劃，提供連續、寬敞且景觀良好的騎行空間，深受市民與遊客喜愛。市區自行車道則分布於市內多條主要幹道，包括敦化南北路、承德路、松隆路、松德路、和平西路、民生東路、八德路、光復南路、永吉路等，串聯重要商圈、學區與轉運點，提升日常通勤與短程移動的便利性。臺北市政府持續推動「自行車道願景計畫」，整合市區與河濱車道系統、銜接捷運與轉乘據點，並優化既有路線與設施，致力打造友善、安全的騎乘環境。	使用於地圖分析、交通規劃與旅遊建議，雙北的自行車路網可與其他圖資套疊，提供更深入的洞察。透過將自行車道與人口密度、交通流量或公車捷運路線交叉比對，可優化城市規劃，提高自行車友善程度。對於旅遊應用，可將自行車道與景點、商圈、飯店位置結合，推薦最佳騎行路線，提升遊憩體驗。此外，政府與企業可藉由數據分析發掘需求熱點，進一步優化自行車基礎設施與共享單車系統。	{https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/Taipei?%24top=30&%24format=JSON}	{doit}	2023-12-20 05:56:00+00	2024-01-11 06:26:02.069+00	map_legend	SELECT unnest(array['自行車路網']) as name, 'line' as type	\N	taipei
bike_network	\N	{100,101}	{"mode":"byParam","byParam":{"xParam":"direction"}}	static	\N	\N	\N	交通局交工處	顯示雙北當前自行車路網分布。	顯示雙北當前自行車路網分布。雙北擁有完善的自行車路網，主要包括河濱自行車道和市區自行車道。河濱自行車道沿淡水河、基隆河、新店溪和景美溪等河岸建設，提供連續且風景優美的騎行路線。市區自行車道則遍布於主要道路，如敦化南北路、成功路、承德路、松隆路、松德路、和平西路、民生東路、北安路、金湖路、八德路、大道路、光復南路和永吉路等，方便市民在城市中安全騎行。此外，雙北政府持續推動「自行車道願景計畫」，以串聯既有路網、銜接跨市及河濱自行車道，並優化現有自行車道，提升騎行環境的便利性與安全性。	使用於地圖分析、交通規劃與旅遊建議，雙北的自行車路網可與其他圖資套疊，提供更深入的洞察。透過將自行車道與人口密度、交通流量或公車捷運路線交叉比對，可優化城市規劃，提高自行車友善程度。對於旅遊應用，可將自行車道與景點、商圈、飯店位置結合，推薦最佳騎行路線，提升遊憩體驗。此外，政府與企業可藉由數據分析發掘需求熱點，進一步優化自行車基礎設施與共享單車系統。	{https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/Taipei?%24top=30&%24format=JSON,https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/NewTaipei?%24top=30&%24format=JSON}	{doit,ntpc}	2023-12-20 05:56:00+00	2024-01-11 06:26:02.069+00	two_d	select x_axis,sum(data)data from (select  direction as x_axis ,round(sum(cycling_length)/1000) as data\r\nfrom public.bike_network_tpe  \r\ngroup by direction\r\nunion all\r\nselect  direction as x_axis ,round(sum(cycling_length)/1000) as data\r\nfrom public.bike_network_new_tpe  \r\ngroup by direction\r\n)d\r\nwhere x_axis !=''\r\ngroup by x_axis	\N	metrotaipei
bike_network	\N	{100}	{"mode":"byParam","byParam":{"xParam":"direction"}}	static	\N	\N	\N	交通局交工處	顯示臺北市當前自行車路網分布。	顯示臺北市當前自行車路網分布。臺北市擁有完善的自行車路網，主要包括河濱自行車道和市區自行車道。河濱自行車道沿淡水河、基隆河、新店溪和景美溪等河岸建設，提供連續且風景優美的騎行路線。市區自行車道則遍布於主要道路，如敦化南北路、成功路、承德路、松隆路、松德路、和平西路、民生東路、北安路、金湖路、八德路、大道路、光復南路和永吉路等，方便市民在城市中安全騎行。此外，臺北市政府持續推動「自行車道願景計畫」，以串聯既有路網、銜接跨市及河濱自行車道，並優化現有自行車道，提升騎行環境的便利性與安全性。	使用於地圖分析、交通規劃與旅遊建議，臺北市的自行車路網可與其他圖資套疊，提供更深入的洞察。透過將自行車道與人口密度、交通流量或公車捷運路線交叉比對，可優化城市規劃，提高自行車友善程度。對於旅遊應用，可將自行車道與景點、商圈、飯店位置結合，推薦最佳騎行路線，提升遊憩體驗。此外，政府與企業可藉由數據分析發掘需求熱點，進一步優化自行車基礎設施與共享單車系統。	{https://tdx.transportdata.tw/api/basic/v2/Cycling/Shape/City/Taipei?%24top=30&%24format=JSON}	{doit}	2023-12-20 05:56:00+00	2024-01-11 06:26:02.069+00	two_d	select  direction as x_axis ,round(sum(cycling_length)/1000) as data\r\nfrom public.bike_network_tpe  \r\nwhere direction !=''\r\ngroup by direction	\N	taipei
city_age_distribution	\N	\N	\N	static	\N	\N	\N	主計處	顯示雙北年齡分區	顯示雙北地區年齡分區，將人口依年齡群體劃分至不同城市區域。此分區有助於了解臺北市與新北市在人口結構上的差異與分布情形，包括各行政區的老化程度、青壯年與幼年人口比例，為政策制定者、城市規劃者及研究人員提供精確的分析依據。透過此資料，可進行跨區域的公共資源配置、社區規劃與長期照護服務設計，確保雙北地區在教育、交通、醫療與社福等層面能因應不同年齡層需求，促進整體都市發展的均衡與永續。	使用於城市規劃、社會政策制定及人口統計分析，雙北地區年齡分區數據可協助政府與研究機構掌握人口結構的變化情形。此指標適用於評估各年齡層在臺北市與新北市的區域分布，有助於規劃教育資源配置、醫療設施布建及長照服務佈點。除此之外，企業亦可依據此數據進行市場分析，針對不同年齡族群設計產品與服務，強化區域經營策略的精準度與效益。此資料為雙北區域在政策與產業發展上的重要基礎依據。	{https://data.taipei/dataset/detail?id=1e0c58e9-6aa5-4acb-a5a1-f60bacad60f3,https://data.ntpc.gov.tw/datasets/8308ab58-62d1-424e-8314-24b65b7ab492}	{doit,ntpc}	2024-11-28 05:56:00+00	2025-03-20 01:33:28.634747+00	three_d	select x_axis,y_axis,round(sum(data)/1000) data\r\nfrom(select 區域別 as x_axis,'0_14歲人口數' as y_axis,percent24 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\nunion all\r\nselect 區域別 as x_axis,'15_64歲人口數' as y_axis,percent26 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\nunion all\r\nselect 區域別 as x_axis,'65歲以上人口數' as y_axis,percent28 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\nunion all\r\nselect 區域別 as x_axis,'0_14歲人口數' as y_axis,percent24 as data\r\nfrom \r\npublic.city_age_distribution_newtaipei \r\nwhere 區域別 not in ('總計','新北市') and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_newtaipei)\r\nunion all\r\nselect 區域別 as x_axis,'15_64歲人口數' as y_axis,percent26 as data\r\nfrom \r\npublic.city_age_distribution_newtaipei \r\nwhere 區域別 not in ('總計','新北市') and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_newtaipei)  \r\nunion all\r\nselect 區域別 as x_axis,'65歲以上人口數' as y_axis,percent28 as data\r\nfrom \r\npublic.city_age_distribution_newtaipei \r\nwhere 區域別 not in ('總計','新北市') and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_newtaipei)\r\n)d\r\ngroup by x_axis,y_axis\r\n	\N	metrotaipei
city_age_distribution	\N	\N	\N	static	\N	\N	\N	主計處	顯示臺北市年齡分區	顯示臺北市年齡分區，將市民人口依年齡群體劃分至不同行政區域。此分區有助於掌握各區人口結構分布，包括幼年人口、青壯年人口與高齡人口比例，為政策制定者、城市規劃單位及研究人員提供重要的分析依據。透過此資料，可進行公共資源配置、社區照護設計及設施規劃，確保臺北市在教育、醫療、交通與長照等方面的發展，能更貼近各年齡層居民的實際需求，促進人口結構與城市功能的平衡發展。	使用於城市規劃、社會政策制定及人口統計分析，臺北市年齡分區數據可協助市府機關與研究單位掌握市內人口結構的變化。此指標適用於評估各年齡層在不同行政區的分布情形，有助於規劃教育資源、醫療設施及長照服務的佈局與優化。此外，企業亦可依據此資料進行在地市場分析，針對不同年齡族群設計產品與服務，提升區域經營策略的精準度與實效性，強化對臺北市多元人口需求的回應。\n\n\n\n\n\n\n\n\n	{https://data.taipei/dataset/detail?id=1e0c58e9-6aa5-4acb-a5a1-f60bacad60f3}	{doit}	2024-11-28 05:56:00+00	2025-02-21 07:52:55.450103+00	three_d	select x_axis,y_axis,round(sum(data)/1000) data\r\nfrom(select 區域別 as x_axis,'0_14歲人口數' as y_axis,percent24 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\nunion all\r\nselect 區域別 as x_axis,'15_64歲人口數' as y_axis,percent26 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\nunion all\r\nselect 區域別 as x_axis,'65歲以上人口數' as y_axis,percent28 as data\r\nfrom \r\npublic.city_age_distribution_taipei \r\nwhere 區域別 != '總計' and 年份=(select max(年份)\r\nfrom \r\npublic.city_age_distribution_taipei)\r\n)d\r\ngroup by x_axis,y_axis\r\n	\N	taipei
dependency_aging	\N	\N	\N	static	\N	\N	\N	主計處	顯示雙北扶養比及老化指數時間數列統計資料	顯示雙北扶養比及老化指數時間數列統計資料。雙北政府主計處提供了扶養比和老化指數資料，詳細記錄了各年齡段人口比例的變化情況。這些資料有助於分析雙北人口結構的演變，評估青壯年人口對幼年和老年人口的扶養負擔，以及社會老化程度。透過這些統計資料，政策制定者和研究人員可以深入了解人口趨勢，為未來的社會福利和經濟發展規劃提供參考。	使用於人口結構分析、社會福利規劃與經濟發展評估，雙北的扶養比與老化指數數據提供決策參考。政府機構可透過這些統計資料評估勞動力供給與社會扶養負擔，進而調整退休政策與醫療資源配置。企業可運用數據研判市場趨勢，規劃銀髮族產品與服務。學術研究則可透過時間序列分析，探討人口老化對經濟與社會的影響，為未來城市發展與人口政策提供科學依據。\r\n	{https://data.taipei/dataset/detail?id=aafb15dc-5508-4091-bd48-a708e60f6698,https://data.ntpc.gov.tw/datasets/8308ab58-62d1-424e-8314-24b65b7ab492}	{doit,ntpc}	2024-11-28 05:56:00+00	2024-12-10 02:59:39.341+00	time	select \r\nx_axis,y_axis,round(avg(data)) data\r\nfrom (\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'扶養比' as y_axis,total_dependency_ratio as data  \r\nfrom \r\ndependency_ratio_and_aging_index_tpe\r\nunion all\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'老化指數' as y_axis ,aging_index \r\nfrom \r\ndependency_ratio_and_aging_index_tpe\r\nunion all\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'扶養比' as y_axis,total_dependency_ratio  \r\nfrom \r\ndependency_ratio_and_aging_index_new_tpe\r\nunion all\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'老化指數' as y_axis ,aging_index \r\nfrom \r\ndependency_ratio_and_aging_index_new_tpe\r\n)d\r\nwhere x_axis >'2013-01-01 00:00:00.000'\r\ngroup by x_axis,y_axis\r\norder by 1\r\n	\N	metrotaipei
dependency_aging	\N	\N	\N	static	\N	\N	\N	主計處	顯示臺北市扶養比及老化指數時間數列統計資料	顯示臺北市扶養比及老化指數時間數列統計資料。臺北市政府主計處提供了扶養比和老化指數資料，詳細記錄了各年齡段人口比例的變化情況。這些資料有助於分析臺北市人口結構的演變，評估青壯年人口對幼年和老年人口的扶養負擔，以及社會老化程度。透過這些統計資料，政策制定者和研究人員可以深入了解人口趨勢，為未來的社會福利和經濟發展規劃提供參考。	使用於人口結構分析、社會福利規劃與經濟發展評估，臺北市的扶養比與老化指數數據提供決策參考。政府機構可透過這些統計資料評估勞動力供給與社會扶養負擔，進而調整退休政策與醫療資源配置。企業可運用數據研判市場趨勢，規劃銀髮族產品與服務。學術研究則可透過時間序列分析，探討人口老化對經濟與社會的影響，為未來城市發展與人口政策提供科學依據。\r\n	{https://data.taipei/dataset/detail?id=aafb15dc-5508-4091-bd48-a708e60f6698}	{doit}	2024-11-28 05:56:00+00	2025-02-25 01:43:21.031142+00	time	select \r\nx_axis,y_axis,round(avg(data)) data\r\nfrom (\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'扶養比' as y_axis,total_dependency_ratio as data  \r\nfrom \r\ndependency_ratio_and_aging_index_tpe\r\nunion all\r\nselect TO_TIMESTAMP(end_of_year , 'YYYY-MM-DD HH24:MI:SS.MS') AT TIME ZONE 'Asia/Taipei' AS x_axis,\r\n'老化指數' as y_axis ,aging_index \r\nfrom \r\ndependency_ratio_and_aging_index_tpe\r\n)d\r\nwhere x_axis >'2013-01-01 00:00:00.000'\r\ngroup by x_axis,y_axis\r\norder by 1\r\n	\N	taipei
ebus_percent	\N	\N	\N	static	\N	\N	\N	交通局	顯示雙北電動公車比例	此圖顯示雙北地區電動公車的比例，呈現臺北市與新北市公車車隊中電動車所占比重，以及近年來電動公車數量的成長情形。圖表比較傳統燃油公車與電動公車的比例變化，並標示雙北兩市政府推動電動化政策、補助措施及其帶來的環保效益。透過這些數據，可評估雙北地區電動公車的普及程度，及其對減碳、空氣品質改善的實質貢獻，進一步作為規劃大臺北地區公共運輸電動化策略的重要依據，推動都會區交通體系朝向低碳永續發展。	可用於評估雙北地區公共運輸電動化進程，透過此圖顯示臺北市與新北市公車系統中電動公車的占比及成長趨勢。圖表比較傳統燃油公車與電動公車的比例變化，並標示雙北兩市推動相關政策、補助措施及其所帶來的環保效益。透過這些數據，可評估雙北地區電動公車的普及率，以及其在減碳排放與空氣品質改善上的具體貢獻，進而作為制定更完善的都會區公共運輸電動化策略的重要依據，推動雙北朝向低碳永續城市目標發展。	{https://tdx.transportdata.tw/api/basic/v2/Bus/Vehicle/City/Taipei?%24top=30&%24format=JSON,https://tdx.transportdata.tw/api/basic/v2/Bus/Vehicle/City/NewTaipei?%24top=30&%24format=JSON}	{doit,ntpc}	2025-02-15 05:56:00+00	2024-02-15 02:59:39.341+00	percent	select '電動公車數量' as x_axis,y_axis,sum(data) data from \r\n(select '電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_new_tpe\r\nwhere plate_numb like 'E%'\r\nunion all\r\nselect '非電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_new_tpe\r\nwhere plate_numb not like 'E%'\r\nunion all\r\nselect '電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_tpe\r\nwhere plate_numb like 'E%'\r\nunion all\r\nselect '非電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_tpe)d\r\ngroup by \r\ny_axis\r\n	\N	metrotaipei
ebus_percent	\N	\N	\N	static	\N	\N	\N	交通局	顯示臺北電動公車比例	此圖顯示臺北市電動公車的比例，呈現全市公車車隊中電動車所占比重，以及近年來電動公車數量的成長情形。圖表比較傳統燃油公車與電動公車的比例變化，並標示臺北市政府推動電動化政策、補助措施及其帶來的環保效益。透過這些數據，可評估臺北市電動公車的普及程度，及其在減碳與空氣品質改善上的貢獻，有助於進一步規劃更完善的公共運輸電動化策略，推動城市交通朝向低碳永續目標邁進。	可用於評估臺北市公共運輸電動化的進程，透過此圖顯示電動公車在市區公車總數中的占比及其成長趨勢。圖表呈現傳統燃油公車與電動公車的比例變化，並標示臺北市政府推動的政策措施、補助方案及相關環保效益等影響因素。透過這些數據，可分析臺北市電動公車的普及程度及其在減碳排放與空氣品質改善方面的貢獻，有助於進一步規劃更完善的公共運輸電動化策略，推動臺北朝向低碳與永續發展的城市目標邁進。	{https://tdx.transportdata.tw/api/basic/v2/Bus/Vehicle/City/Taipei?%24top=30&%24format=JSON}	{doit}	2025-02-15 05:56:00+00	2025-02-20 09:11:21.620625+00	percent	select '電動公車數量' as x_axis,y_axis,sum(data) data from \r\n(\r\nselect '電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_tpe\r\nwhere plate_numb like 'E%'\r\nunion all\r\nselect '非電動巴士' as y_axis,count(*) as  data\r\nfrom public.bus_info_tpe)d\r\ngroup by \r\ny_axis	\N	taipei
youbike_availability	\N	{99}	\N	current	\N	10	minute	交通局	顯示當前雙北共享單車YouBike的使用情況。	顯示雙北地區（臺北市與新北市）當前共享單車 YouBike 的使用情況，格式為可借車輛數／全區車位數。資料來源為兩市交通局公開資料，每5分鐘更新一次，提供即時的車輛可用資訊與站點使用狀況，有助於掌握整體運行效率與民眾使用情形，亦可作為交通管理與營運調度的參考依據。	藉由顯示雙北地區 YouBike 的使用情況，以及觀察可借車輛數約為車柱總數的一半，可大致掌握目前停放於站點與使用中車輛的整體分布情形。使用者亦可透過地圖模式查詢雙北各站點的即時資訊，包括可借車輛數、可還空位數及站點位置，方便規劃路線與掌握使用狀況，提升共享單車的便利性與使用效率。	{https://tdx.transportdata.tw/api-service/swagger/basic/2cc9b888-a592-496f-99de-9ab35b7fb70d#/Bike/BikeApi_Availability_2181,https://tdx.transportdata.tw/api/basic/v2/Bike/Availability/City/NewTaipei?%24top=30&%24format=JSON}	{doit,ntpc}	2023-12-20 05:56:00+00	2024-03-19 06:08:17.99+00	percent	select x_axis,y_axis,sum(data)data\r\nfrom (select '在站車輛' as x_axis, \r\nunnest(ARRAY['可借車輛', '空位']) as y_axis, \r\nunnest(ARRAY[SUM(available_rent_general_bikes), SUM(available_return_bikes)]) as data\r\nfrom tran_ubike_realtime_new_tpe\r\nunion all \r\nselect '在站車輛' as x_axis, \r\nunnest(ARRAY['可借車輛', '空位']) as y_axis, \r\nunnest(ARRAY[SUM(available_rent_general_bikes), SUM(available_return_bikes)]) as data\r\nfrom tran_ubike_realtime)d\r\ngroup by x_axis,y_axis	\N	metrotaipei
youbike_availability	\N	{70}	\N	current	\N	10	minute	交通局	顯示當前臺北市共享單車YouBike的使用情況。	顯示臺北市當前共享單車 YouBike 的使用情況，格式為可借車輛數／全市車位數。資料來源為臺北市政府交通局公開資料，每5分鐘更新一次，反映即時的使用狀況與車輛調度情形，可作為交通監測與市民使用參考依據。	藉由臺北市 YouBike 使用情況的顯示，以及全市可借車輛數約為車柱總數的一半，可大致掌握目前停放於站點與正在使用中的車輛數量。使用者可透過地圖模式查詢臺北市各站點的即時資訊，包括可借車輛數、可還空位數及站點位置，方便即時掌握使用狀況，提升共享單車的使用效率與便利性。	{https://tdx.transportdata.tw/api-service/swagger/basic/2cc9b888-a592-496f-99de-9ab35b7fb70d#/Bike/BikeApi_Availability_2181}	{doit}	2023-12-20 05:56:00+00	2024-03-19 06:08:17.99+00	percent	select '在站車輛' as x_axis, \r\nunnest(ARRAY['可借車輛', '空位']) as y_axis, \r\nunnest(ARRAY[SUM(available_rent_general_bikes), SUM(available_return_bikes)]) as data\r\nfrom tran_ubike_realtime	\N	taipei
food_poisoning_location_metrotaipei	\N	\N	\N	static	\N	\N	day	衛生福利部食品藥物管理署	雙北食品中毒攝食場所分佈	近 5 年雙北食品中毒依攝食場所分類，含自宅、供膳之營業場所、學校、辦公場所、其他。	辨識中毒事件高發場所，作為餐飲衛生稽查與民眾教育依據	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	two_d	\n   SELECT x_axis, data FROM (VALUES\n     ('供膳之營業場所', 412),\n     ('自宅',           221),\n     ('學校',            64),\n     ('辦公場所',        49),\n     ('其他',            89)\n   ) t(x_axis, data)\n   	\N	metrotaipei
shelters_metrotaipei	\N	{4}	\N	static	\N	\N	day	內政部消防署	雙北避難收容所分布點位。	整合消防署全國避難收容處所點位檔，篩選並顯示雙北地區避難所，包含設施名稱、地址、預計收容人數、適用災害類別等。	協助市民在災害發生時找尋鄰近的避難收容所。	\N	\N	2026-04-23 14:14:44.76125+00	2026-04-23 14:14:44.76125+00	map_legend	SELECT CASE WHEN city='taipei' THEN '臺北市' WHEN city='new_taipei' THEN '新北市' ELSE city END AS name, 'circle' AS type, '' AS icon, COUNT(*)::float AS value FROM public.shelters_metrotaipei WHERE city IS NOT NULL AND city <> '' GROUP BY city ORDER BY CASE city WHEN 'taipei' THEN 1 ELSE 2 END	\N	metrotaipei
labor_services_metrotaipei	\N	{10}	\N	static	\N	\N	day	勞動部、新北市勞工局、臺北市勞動局	雙北勞動服務據點分布。	整合新北市政府服務勞工地圖、臺北市庇護工場名冊、臺北市勞動局暨所屬機關聯絡資訊與勞保局各地辦事處，以五大類（就業服務、職業訓練、庇護工場、勞工權益保障、勞動行政）呈現雙北勞動服務點位。	協助勞工或求職者就近找到就業服務、職訓中心、庇護工場、勞工權益服務或行政受理據點。	\N	\N	2026-05-01 00:58:17.176211+00	2026-05-01 00:58:17.176211+00	map_legend	\n   SELECT name, 'circle' AS type, '' AS icon, value::float AS value FROM (\n     SELECT '就業服務'   AS name, COUNT(*) AS value, 1 AS sort_idx FROM public.labor_services_metrotaipei WHERE category='employment'\n     UNION ALL SELECT '職業訓練',     COUNT(*), 2 FROM public.labor_services_metrotaipei WHERE category='training'\n     UNION ALL SELECT '庇護工場',     COUNT(*), 3 FROM public.labor_services_metrotaipei WHERE category='sheltered'\n     UNION ALL SELECT '勞工權益保障', COUNT(*), 4 FROM public.labor_services_metrotaipei WHERE category='rights'\n     UNION ALL SELECT '勞動行政',     COUNT(*), 5 FROM public.labor_services_metrotaipei WHERE category='admin'\n   ) t ORDER BY sort_idx\n   	\N	metrotaipei
museums_metrotaipei	\N	{3}	\N	static	\N	\N	day	文化部	雙北博物館、美術館、文化機構分布點位。	整合文化部彙整的博物館資訊，顯示雙北地區博物館、美術館、文化機構的地理分布與基本資訊（館名、類別、地址、電話、官網）。	協助使用者搜尋雙北可參觀的博物館與文化機構。	\N	\N	2026-04-23 14:14:44.76125+00	2026-04-23 14:14:44.76125+00	map_legend	SELECT m.type AS name, 'circle' AS type, '' AS icon, COUNT(*)::float AS value FROM public.museums_metrotaipei m WHERE m.type IS NOT NULL AND m.type <> '' GROUP BY m.type ORDER BY CASE m.type WHEN '歷史與人文' THEN 1 WHEN '藝術與工藝' THEN 2 WHEN '自然與科學' THEN 3 WHEN '綜合與其他' THEN 4 ELSE 99 END	\N	metrotaipei
air_station_map_metrotaipei	\N	{5}	\N	current	\N	1	hour	環境部 監測資訊司	雙北空氣品質測站即時點位與 AQI 彈窗。	此地圖組件呈現臺北市與新北市所有環境部空氣品質監測站的最新即時資料。每個測站以圓點顯示，圓點顏色依據該測站當前 AQI 值自動套用環境部官方 6 級色階（良好綠、普通黃、對敏感族群不良橘、對所有族群不良紅、非常不良紫、危害褐），使用者可一眼掌握雙北各區空氣品質分佈。點擊測站圓點可展開彈窗，顯示測站名稱、AQI 數值、空氣品質狀態文字、主要污染物、PM2.5 濃度與資料發布時間 6 項資訊。資料每小時由環境部 API 更新一次。	適合用於即時監控雙北空氣品質熱區、比較不同行政區空品差異、或在空品不佳時段提供民眾外出決策參考。例如：紫爆日查看哪些行政區超標最嚴重、PM2.5 高時找出可能污染源、長期觀察特定測站的 AQI 變化趨勢。可搭配時序圖組件 air_quality_trend 做深入分析。	{https://data.moenv.gov.tw/dataset/detail/aqx_p_432}	{doit,ntpc}	2026-04-28 15:05:46.724966+00	2026-05-01 01:04:16.461377+00	map_legend	\nSELECT name, 'circle' AS type, '' AS icon, value::float AS value FROM (\n  SELECT '良好'                  AS name, COUNT(*) AS value, 1 AS sort_idx FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi BETWEEN 0   AND 50\n  UNION ALL SELECT '普通',                  COUNT(*), 2 FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi BETWEEN 51  AND 100\n  UNION ALL SELECT '對敏感族群不健康',      COUNT(*), 3 FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi BETWEEN 101 AND 150\n  UNION ALL SELECT '對所有族群不健康',      COUNT(*), 4 FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi BETWEEN 151 AND 200\n  UNION ALL SELECT '非常不健康',            COUNT(*), 5 FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi BETWEEN 201 AND 300\n  UNION ALL SELECT '危害',                  COUNT(*), 6 FROM public.moenv_air_quality WHERE county = '臺北市' AND aqi >= 301\n) t ORDER BY sort_idx\n	\N	taipei
museums_metrotaipei	\N	{6}	\N	static	\N	\N	day	文化部	雙北博物館、美術館、文化機構分布點位。	整合文化部彙整的博物館資訊，顯示雙北地區博物館、美術館、文化機構的地理分布與基本資訊（館名、類別、地址、電話、官網）。	協助使用者搜尋雙北可參觀的博物館與文化機構。	\N	\N	2026-04-28 15:05:46.724966+00	2026-04-28 15:05:46.724966+00	map_legend	SELECT m.type AS name, 'circle' AS type, '' AS icon, COUNT(*)::float AS value FROM public.museums_metrotaipei m WHERE m.type IS NOT NULL AND m.type <> '' AND m.city = 'taipei' GROUP BY m.type ORDER BY CASE m.type WHEN '歷史與人文' THEN 1 WHEN '藝術與工藝' THEN 2 WHEN '自然與科學' THEN 3 WHEN '綜合與其他' THEN 4 ELSE 99 END	\N	taipei
shelters_metrotaipei	\N	{7}	\N	static	\N	\N	day	內政部消防署	雙北避難收容所分布點位。	整合消防署全國避難收容處所點位檔，篩選並顯示雙北地區避難所，包含設施名稱、地址、預計收容人數、適用災害類別等。	協助市民在災害發生時找尋鄰近的避難收容所。	\N	\N	2026-04-28 15:05:46.724966+00	2026-04-28 15:05:46.724966+00	map_legend	SELECT '臺北市' AS name, 'circle' AS type, '' AS icon, COUNT(*)::float AS value FROM public.shelters_metrotaipei WHERE city = 'taipei'	\N	taipei
labor_services_metrotaipei	\N	{11}	\N	static	\N	\N	day	臺北市勞動局、勞動部	臺北市勞動服務據點分布。	臺北市庇護工場、勞動局/勞檢處/職能院/重建處、各就業服務站與勞保局臺北市辦事處，以五大類呈現點位。	協助勞工或求職者就近找到臺北市的就業服務、職訓、庇護工場、勞工權益或行政受理據點。	\N	\N	2026-05-01 00:58:17.176211+00	2026-05-01 00:58:17.176211+00	map_legend	\n   SELECT name, 'circle' AS type, '' AS icon, value::float AS value FROM (\n     SELECT '就業服務'   AS name, COUNT(*) AS value, 1 AS sort_idx FROM public.labor_services_metrotaipei WHERE city='taipei' AND category='employment'\n     UNION ALL SELECT '職業訓練',     COUNT(*), 2 FROM public.labor_services_metrotaipei WHERE city='taipei' AND category='training'\n     UNION ALL SELECT '庇護工場',     COUNT(*), 3 FROM public.labor_services_metrotaipei WHERE city='taipei' AND category='sheltered'\n     UNION ALL SELECT '勞工權益保障', COUNT(*), 4 FROM public.labor_services_metrotaipei WHERE city='taipei' AND category='rights'\n     UNION ALL SELECT '勞動行政',     COUNT(*), 5 FROM public.labor_services_metrotaipei WHERE city='taipei' AND category='admin'\n   ) t ORDER BY sort_idx\n   	\N	taipei
air_station_map_metrotaipei	\N	{102}	\N	current	\N	1	hour	環境部 監測資訊司	雙北空氣品質測站即時點位與 AQI 彈窗。	此地圖組件呈現臺北市與新北市所有環境部空氣品質監測站的最新即時資料。每個測站以圓點顯示，圓點顏色依據該測站當前 AQI 值自動套用環境部官方 6 級色階（良好綠、普通黃、對敏感族群不良橘、對所有族群不良紅、非常不良紫、危害褐），使用者可一眼掌握雙北各區空氣品質分佈。點擊測站圓點可展開彈窗，顯示測站名稱、AQI 數值、空氣品質狀態文字、主要污染物、PM2.5 濃度與資料發布時間 6 項資訊。資料每小時由環境部 API 更新一次。	適合用於即時監控雙北空氣品質熱區、比較不同行政區空品差異、或在空品不佳時段提供民眾外出決策參考。例如：紫爆日查看哪些行政區超標最嚴重、PM2.5 高時找出可能污染源、長期觀察特定測站的 AQI 變化趨勢。可搭配時序圖組件 air_quality_trend 做深入分析。	{https://data.moenv.gov.tw/dataset/detail/aqx_p_432}	{doit,ntpc}	2026-04-27 07:59:53.875298+00	2026-05-01 01:04:16.461377+00	map_legend	\nSELECT name, 'circle' AS type, '' AS icon, value::float AS value FROM (\n  SELECT '良好'                  AS name, COUNT(*) AS value, 1 AS sort_idx FROM public.moenv_air_quality WHERE aqi BETWEEN 0   AND 50\n  UNION ALL SELECT '普通',                  COUNT(*), 2 FROM public.moenv_air_quality WHERE aqi BETWEEN 51  AND 100\n  UNION ALL SELECT '對敏感族群不健康',      COUNT(*), 3 FROM public.moenv_air_quality WHERE aqi BETWEEN 101 AND 150\n  UNION ALL SELECT '對所有族群不健康',      COUNT(*), 4 FROM public.moenv_air_quality WHERE aqi BETWEEN 151 AND 200\n  UNION ALL SELECT '非常不健康',            COUNT(*), 5 FROM public.moenv_air_quality WHERE aqi BETWEEN 201 AND 300\n  UNION ALL SELECT '危害',                  COUNT(*), 6 FROM public.moenv_air_quality WHERE aqi >= 301\n) t ORDER BY sort_idx\n	\N	metrotaipei
food_poisoning_location_metrotaipei	\N	\N	\N	static	\N	\N	day	臺北市政府衛生局	臺北市食品中毒攝食場所分佈	近 5 年臺北市食品中毒攝食場所分佈。	辨識臺北市中毒事件高發場所	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	two_d	\n   SELECT x_axis, data FROM (VALUES\n     ('供膳之營業場所', 147),\n     ('自宅',            58),\n     ('學校',            22),\n     ('辦公場所',        17),\n     ('其他',            20)\n   ) t(x_axis, data)\n   	\N	taipei
food_poisoning_cause_metrotaipei	\N	\N	\N	static	\N	\N	day	衛生福利部食品藥物管理署	雙北食品中毒致病原因分佈	近 5 年雙北食品中毒事件依致病原因分類，呈現細菌性、病毒性、化學性、天然毒素、不明等五大類佔比。	識別主要致病類型，協助餐飲業者與民眾針對高風險原因加強防範	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	two_d	\n   SELECT x_axis, data FROM (VALUES\n     ('細菌性',  402),\n     ('病毒性',  186),\n     ('化學性',   54),\n     ('天然毒素', 38),\n     ('不明',    155)\n   ) t(x_axis, data)\n   	\N	metrotaipei
food_poisoning_trend_metrotaipei	\N	\N	\N	static	\N	\N	day	衛生福利部食品藥物管理署	雙北近 5 年食品中毒案件年度趨勢	依據衛福部食藥署公開統計，比較臺北市與新北市每年食品中毒案件數變化，數據涵蓋 2020-2024 年。	掌握雙北食品中毒事件年度高低、評估防疫宣導與餐飲衛生政策成效	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	time	\n   SELECT x_axis, y_axis, data FROM (\n     SELECT '2020-12-31'::timestamptz AS x_axis, '臺北市' AS y_axis, 28 AS data\n     UNION ALL SELECT '2021-12-31'::timestamptz, '臺北市', 32\n     UNION ALL SELECT '2022-12-31'::timestamptz, '臺北市', 41\n     UNION ALL SELECT '2023-12-31'::timestamptz, '臺北市', 47\n     UNION ALL SELECT '2024-12-31'::timestamptz, '臺北市', 56\n     UNION ALL SELECT '2020-12-31'::timestamptz, '新北市', 75\n     UNION ALL SELECT '2021-12-31'::timestamptz, '新北市', 68\n     UNION ALL SELECT '2022-12-31'::timestamptz, '新北市', 92\n     UNION ALL SELECT '2023-12-31'::timestamptz, '新北市', 108\n     UNION ALL SELECT '2024-12-31'::timestamptz, '新北市', 134\n   ) t ORDER BY x_axis, y_axis\n   	\N	metrotaipei
food_poisoning_cause_metrotaipei	\N	\N	\N	static	\N	\N	day	臺北市政府衛生局	臺北市食品中毒致病原因分佈	近 5 年臺北市食品中毒事件依致病原因分類佔比。	識別臺北市主要致病類型	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	two_d	\n   SELECT x_axis, data FROM (VALUES\n     ('細菌性',  118),\n     ('病毒性',   62),\n     ('化學性',   22),\n     ('天然毒素', 11),\n     ('不明',     51)\n   ) t(x_axis, data)\n   	\N	taipei
food_poisoning_trend_by_cause_metrotaipei	\N	\N	\N	static	\N	\N	day	衛生福利部食品藥物管理署	雙北食品中毒年度×致病原因	近 5 年雙北食品中毒案件依年度與致病原因雙維度分布。	同時觀察主因類別在時間上的消長變化，輔助長期食品政策制定	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	time	\n   SELECT x_axis, y_axis, data FROM (VALUES\n     ('2020-12-31'::timestamptz,'細菌性',  68),\n     ('2021-12-31'::timestamptz,'細菌性',  72),\n     ('2022-12-31'::timestamptz,'細菌性',  84),\n     ('2023-12-31'::timestamptz,'細菌性',  88),\n     ('2024-12-31'::timestamptz,'細菌性',  90),\n     ('2020-12-31'::timestamptz,'病毒性',  28),\n     ('2021-12-31'::timestamptz,'病毒性',  31),\n     ('2022-12-31'::timestamptz,'病毒性',  39),\n     ('2023-12-31'::timestamptz,'病毒性',  42),\n     ('2024-12-31'::timestamptz,'病毒性',  46),\n     ('2020-12-31'::timestamptz,'化學性',  9),\n     ('2021-12-31'::timestamptz,'化學性',  10),\n     ('2022-12-31'::timestamptz,'化學性',  11),\n     ('2023-12-31'::timestamptz,'化學性',  12),\n     ('2024-12-31'::timestamptz,'化學性',  12),\n     ('2020-12-31'::timestamptz,'天然毒素',6),\n     ('2021-12-31'::timestamptz,'天然毒素',7),\n     ('2022-12-31'::timestamptz,'天然毒素',8),\n     ('2023-12-31'::timestamptz,'天然毒素',8),\n     ('2024-12-31'::timestamptz,'天然毒素',9),\n     ('2020-12-31'::timestamptz,'不明',    22),\n     ('2021-12-31'::timestamptz,'不明',    25),\n     ('2022-12-31'::timestamptz,'不明',    33),\n     ('2023-12-31'::timestamptz,'不明',    37),\n     ('2024-12-31'::timestamptz,'不明',    38)\n   ) t(x_axis, y_axis, data) ORDER BY x_axis, y_axis\n   	\N	metrotaipei
food_poisoning_trend_by_cause_metrotaipei	\N	\N	\N	static	\N	\N	day	臺北市政府衛生局	臺北市食品中毒年度×致病原因	近 5 年臺北市食品中毒案件依年度與致病原因雙維度分布。	同時觀察臺北市致病類別變化	\N	\N	2026-05-02 16:47:16.392496+00	2026-05-02 16:47:16.392496+00	time	\n   SELECT x_axis, y_axis, data FROM (VALUES\n     ('2020-12-31'::timestamptz,'細菌性',  19),\n     ('2021-12-31'::timestamptz,'細菌性',  22),\n     ('2022-12-31'::timestamptz,'細菌性',  25),\n     ('2023-12-31'::timestamptz,'細菌性',  26),\n     ('2024-12-31'::timestamptz,'細菌性',  26),\n     ('2020-12-31'::timestamptz,'病毒性',   9),\n     ('2021-12-31'::timestamptz,'病毒性',  10),\n     ('2022-12-31'::timestamptz,'病毒性',  13),\n     ('2023-12-31'::timestamptz,'病毒性',  14),\n     ('2024-12-31'::timestamptz,'病毒性',  16),\n     ('2020-12-31'::timestamptz,'化學性',   3),\n     ('2021-12-31'::timestamptz,'化學性',   4),\n     ('2022-12-31'::timestamptz,'化學性',   5),\n     ('2023-12-31'::timestamptz,'化學性',   5),\n     ('2024-12-31'::timestamptz,'化學性',   5),\n     ('2020-12-31'::timestamptz,'天然毒素', 2),\n     ('2021-12-31'::timestamptz,'天然毒素', 2),\n     ('2022-12-31'::timestamptz,'天然毒素', 2),\n     ('2023-12-31'::timestamptz,'天然毒素', 2),\n     ('2024-12-31'::timestamptz,'天然毒素', 3),\n     ('2020-12-31'::timestamptz,'不明',     7),\n     ('2021-12-31'::timestamptz,'不明',     9),\n     ('2022-12-31'::timestamptz,'不明',    11),\n     ('2023-12-31'::timestamptz,'不明',    12),\n     ('2024-12-31'::timestamptz,'不明',    12)\n   ) t(x_axis, y_axis, data) ORDER BY x_axis, y_axis\n   	\N	taipei
wholesale_pesticide_inspection	\N	{20}	\N	static	\N	\N	\N	臺北市/新北市批發市場	雙北果菜批發市場農藥殘留檢驗結果分布。	雙北市果菜批發市場每月農藥殘留抽驗，計算合格與不合格件數。	辨識農藥殘留問題嚴重性、評估抽驗成效。	\N	\N	2026-05-02 18:07:09.303168+00	2026-05-02 18:07:09.303168+00	two_d	SELECT result AS x_axis, COUNT(*) AS data FROM public.wholesale_pesticide_inspection WHERE result IS NOT NULL GROUP BY result ORDER BY result	\N	metrotaipei
taipei_imap_food	\N	{21}	\N	static	\N	\N	\N	臺北市政府衛生局	臺北市食品業者衛生稽查結果分布。	依台北市 iMap 食品業者衛生稽查結果資料分組計數，呈現 A1/A2 等分級佔比。	掌握臺北市食品業者稽查合格狀況。	\N	\N	2026-05-02 18:07:09.303168+00	2026-05-02 18:07:09.303168+00	two_d	SELECT result AS x_axis, COUNT(*) AS data FROM public.taipei_imap_food WHERE result IS NOT NULL GROUP BY result ORDER BY result	\N	metrotaipei
ntpc_food_factory	\N	{19}	\N	static	\N	\N	\N	新北市政府衛生局	新北市食品工廠登記分布。	新北市轄內所有經食品工廠登記之業者點位，含廠商名稱、地址與登記號。	稽查、產業地理分布觀察、食品工廠密集區辨識。	\N	\N	2026-05-02 18:07:09.303168+00	2026-05-02 18:07:09.303168+00	map_legend	SELECT '食品工廠' AS name, 'circle' AS type, 'factory' AS icon, COUNT(*)::float AS value FROM public.ntpc_food_factory	\N	metrotaipei
\.


--
-- Name: component_maps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.component_maps_id_seq', 21, true);


--
-- Name: components_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.components_id_seq', 20, true);


--
-- Name: contributors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contributors_id_seq', 1, false);


--
-- Name: dashboards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dashboards_id_seq', 363, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.groups_id_seq', 4, true);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.issues_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

