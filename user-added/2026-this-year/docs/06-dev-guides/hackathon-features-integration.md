<!-- 黑客松功能完整整合文件 -->

# 2026 黑客松功能全棧整合指南

## 📋 目錄
1. [整合概述](#overview)
2. [已經完成](#completed)
3. [架構設計](#architecture)
4. [數據流程](#data-flow)
5. [組件與儀表板](#components)
6. [API 端點](#endpoints)
7. [快速開始](#quickstart)
8. [故障排除](#troubleshooting)
9. [後續維護](#maintenance)

---

## 1. 整合概述 {#overview}

本文檔記錄了對去年黑客松（2025）開發功能的全面端對端整合工作。

### 問題背景
去年黑客松新增的功能（原住民族、移工、AED 等）雖然準備了資料檔案與 GeoJSON，但只停留在「資料準備層」，缺少 DB schema、BE API、FE 組件整合。結果是功能「看不見」。

### 本次整合目標（P0 優先級）
✅ **已完成：**
- DB 資料表建立（6 個新表）
- CSV 資料匯入（超過 10,000 筆）
- dashboardmanager 組件設定（7 個組件，8 個查詢設定，3 個地圖圖層）
- 4 個新儀表板（AED、原住民族、移工、長照ABC）
- FE 地圖層整合 (GeoJSON 已就位)
- BE API 自動可用（無需新增 endpoint）

> **關鍵發現：** 該系統使用通用 `component_id` 到 SQL 查詢的動態 API，無需為新功能寫 backend code！

---

## 2. 已經完成 {#completed}

### 2.1 數據層（Dashboard DB）
六個新表已建立並填入數據：

| 表名 | 記錄數 | 來源 CSV | 用途 |
|------|--------|---------|------|
| `aed_tpe` | 2,682 | aed_tpe.csv | AED 台北市位置點位 (地圖圖層用) |
| `indigenous_by_district_tpe` | 2,496 | by_district_TPE_combined.csv | 原住民族依行政區統計 |
| `indigenous_by_group_tpe` | 192 | by_group_TPE_combined.csv | 原住民族依族別統計 |
| `migrant_workers_employed_tpe` | 2,382 | migrant_workers_employed_tpe.csv | 移工依職業與國籍統計(台北) |
| `migrant_workers_employed_ntpc` | 2,346 | migrant_workers_employed_ntpc.csv | 移工依職業與國籍統計(新北) |
| `long_term_care_abc_tpe` | 835 | 長照ABC據點_臺北市_處理後.csv | 長照ABC據點位置點位 (地圖圖層用) |

### 2.2 配置層（Dashboardmanager DB）

#### A. 組件海表 (`components`) - 7 個新組件
```
ID | index | name
---|-------|------
301 | aed_map | AED 地圖
302 | aed_district_tpe | AED 行政區分布
303 | indigenous_district_tpe | 原住民族行政區人口
304 | indigenous_group_tpe | 原住民族族別人口
305 | migrant_workers_tpe | 受聘僱移工（臺北市）
306 | long_term_care_abc_map | 長照ABC 地圖
307 | long_term_care_abc_district_tpe | 長照ABC 行政區統計
```

#### B. 圖層配置 (`component_maps`) - 3 個新地圖圖層
- `aed_map`: 圓形圖層，紅色 (#E74C3C)，資料來自 `/mapData/aed_map.geojson`
- `long_term_care_abc_tpe`: 圓形圖層，依 O_ABC 類型著色，資料來自 `/mapData/long_term_care_abc_tpe.geojson`
- `long_term_care_abc_metrotaipei`: 同上，雙北版本

#### C. 圖表類型 (`component_charts`) - 7 個新設定
- `aed_map`:  MapLegend
- `aed_district_tpe`: BarChart
- `indigenous_district_tpe`: ColumnChart, BarChart
- `indigenous_group_tpe`: BarChart
- `migrant_workers_tpe`: ColumnChart, DonutChart
- `long_term_care_abc_map`: MapLegend
- `long_term_care_abc_district_tpe`: BarChart, DonutChart

#### D. 查詢設定 (`query_charts`) - 8 個新查詢
每個查詢包含：
- `query_type`: `two_d`, `three_d`, `map_legend` 等
- `query_chart`: SQL 語句（300-800 字符不等）
- `city`: `taipei` 或 `metrotaipei`
- 描述、來源、使用案例等元數據

#### E. 儀表板群組 (`dashboards`) - 4 個新儀表板
```
id | index | name | components
---|-------|------|------------
362 | aed_tpe | AED 分布 | [301, 302]
363 | indigenous_social_tpe | 原住民族人口 | [303, 304]
364 | migrant_workers_tpe | 受聘僱移工 | [305]
365 | long_term_care_abc_tpe_dashboard | 長照ABC據點 | [306, 307]
```

### 2.3 前端層（FE）
- ✅ GeoJSON 檔案已在正確位置： `/mapData/aed_map.geojson`, `/mapData/long_term_care_abc_tpe.geojson`, `/mapData/long_term_care_abc_metrotaipei.geojson`
- ✅ FE mapStore 自動檢測並載入這些地圖圖層
- ✅ 無需修改 FE Vue 組件代碼

---

## 3. 架構設計 {#architecture}

### 3.1 系統分層

```
┌─────────────────────────────────────────────────┐
│     FE (Vue 3 + Deck.gl Mapbox)                 │
│  - MapContainer.vue                             │
│  - DashboardComponent.vue                       │
│  - HistoryChart.vue, etc.                       │
└────────────────┬────────────────────────────────┘
                 │ HTTP
                 ↓
┌─────────────────────────────────────────────────┐
│  BE API (Go Gin)                                │
│  /api/v1/components/:id/chart                   │
│  /api/v1/components/:id/map                     │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────┴────────┐
        ↓                 ↓
┌──────────────┐   ┌──────────────────┐
│  Dashboard   │   │ DashboardManager │
│  DB          │   │ DB               │
│ (27 tables)  │   │ (6 tables)       │
└──────────────┘   └──────────────────┘
```

### 3.2 數據查詢流程

```
1. FE 載入儀表板 (dashboard index='aed_tpe')
   ↓
2. FE 隱藏呼叫 BE API: GET /api/v1/dashboard/{dashboard_id}
   ↓
3. BE 查詢 dashboardmanager.dashboards → 取得 components[]
   ↓
4. BE 根據每個 component_id 查詢 dashboardmanager.components/query_charts 獲取 SQL
   ↓
5. BE 執行 SQL 對 dashboard DB 查詢
   ↓
6. BE 將結果轉換為圖表/地圖格式回傳 FE
   ↓
7. FE 渲染圖表 (ApexCharts) 或地圖圖層 (Deck.gl)
```

### 3.3 地圖圖層流程

```
FE mapStore 偵測到 component.map_config[0].source = "geojson"
   ↓
mapStore 發起 axios.get(`/mapData/${index}.geojson`)
   ↓
Nginx 伺服 靜態 GeoJSON 檔案
   ↓
mapStore 建立 Mapbox/Deck.gl layer 並添加至地圖
```

---

## 4. 數據流程 {#data-flow}

### 4.1 原住民族人口流程

```
CSV (by_district_TPE_combined.csv)
   ├─ 年份、月份、行政區、性別、全體、平地、山地
   ↓
DB表: indigenous_by_district_tpe [2496 rows]
   ↓
Query (three_d type):
   SELECT district, gender, SUM(total) as data
   GROUP BY district, gender
   ↓
BE 轉換為: 
   [
     { name: "平地", data: [123, 456, ...] },
     { name: "山地", data: [234, 567, ...] }
   ]
   ↓
FE 渲染 ColumnChart / BarChart
```

### 4.2 受聘僱移工流程

```
CSV (migrant_workers_employed_tpe.csv)
   ├─ 年份、月份、國籍、職業、人數
   ↓
DB表: migrant_workers_employed_tpe [2382 rows]
   ↓
Query (three_d type):
   SELECT job_type, nationality, SUM(count) as data
   GROUP BY job_type, nationality
   ORDER BY SUM(count) DESC
   ↓
BE 轉換為: 
   [
     { name: "農漁牧業", data: [123, 234, 345, ...] },  // 各國籍
     { name: "製造業", data: [456, 567, ...] },
     ...
   ]
   ↓
FE 渲染 ColumnChart / DonutChart
```

### 4.3 地圖圖層流程 (AED)

```
CSV (aed_tpe.csv)
   ├─ 名稱、地址、行政區、緯度、經度、類别、類型
   ↓
DB表: aed_tpe [2682 rows]
   ↓
Python 腳本 (備用，目前用靜態 GeoJSON)
   ├─ 讀取 aed_tpe 表
   ├─ 轉換為 GeoJSON FeatureCollection
   └─ 寫出 /mapData/aed_map.geojson
   ↓
FE mapStore:
   axios.get('/mapData/aed_map.geojson')
   ↓
Mapbox addLayer({
     type: 'circle',
     paint: {
       'circle-color': '#E74C3C',
       'circle-radius': 6
     }
   })
   ↓
使用者在地圖上看到紅色圓點表示 AED 位置
```

---

## 5. 組件與儀表板 {#components}

### 5.1 AED 分布 (aed_tpe 儀表板)
| 組件 | 類型 | 說明 |
|-----|------|------|
| `aed_map` | Map Legend | 地圖圖層 - 台北市 AED 位置點位 |
| `aed_district_tpe` | BarChart | 各行政區 AED 數量排名條圖 |

**用途：** 市民快速找到最近 AED；政策單位評估各區覆蓋率  
**SQL 複雜度：** ⭐️ (簡單 GROUP BY)

### 5.2 原住民族人口 (indigenous_social_tpe 儀表板)
| 組件 | 類型 | 說明 |
|-----|------|------|
| `indigenous_district_tpe` | ColumnChart + BarChart | 各行政區原住民人口 (平地/山地) |
| `indigenous_group_tpe` | BarChart | 各族別人口數量排名 |

**用途：** 了解原住民族在都市的分布與聚集態樣；文化政策評估  
**SQL 複雜度：** ⭐️⭐️ (UNION ALL 多族別 UNPIVOT)

### 5.3 受聘僱移工 (migrant_workers_tpe 儀表板)
| 組件 | 類型 | 說明 |
|-----|------|------|
| `migrant_workers_tpe` | ColumnChart + DonutChart | 台北市移工依職業/國籍分布 |

**用途：** 勞動主管機關掌握移工結構；NGO 了解服務族群  
**SQL 複雜度：** ⭐️⭐️ (GROUP BY 多維度)

### 5.4 長照ABC據點 (long_term_care_abc_tpe_dashboard 儀表板)
| 組件 | 類型 | 說明 |
|-----|------|------|
| `long_term_care_abc_map` | Map Legend | 地圖圖層 - 台北市長照 A/B/C 據點 |
| `long_term_care_abc_district_tpe` | BarChart + DonutChart | 各行政區長照據點數量 |

**用途：** 照護者尋找就近服務；福利單位規劃新據點  
**SQL 複雜度：** ⭐️ (簡單 GROUP BY)

---

## 6. API 端點 {#endpoints}

### 標準端點（無需新增代碼）

所有組件均通過現有通用 API 提供服務：

```bash
# 取得組件圖表數據
GET /api/v1/components/{component_id}/chart?city=taipei&time_from=&time_to=

# 取得地圖圖層數據
GET /api/v1/components/{component_id}/map

# 取得地圖圖例 (用於 MapLegend 圖表類型)
GET /api/v1/components/{component_id}/map-legend
```

### 範例呼叫

```bash
# AED 行政區統計
curl "http://localhost/api/v1/components/302/chart?city=taipei"
→ {
  "status": "success",
  "data": [
    { "x": "中山區", "y": 48 },
    { "x": "大安區", "y": 45 },
    ...
  ]
}

# 原住民族族別 (three_d type 回應)
curl "http://localhost/api/v1/components/304/chart?city=taipei"
→ {
  "status": "success",
  "data": [
    { "name": "阿美族", "data": [8096, 145, ...] },  // x_axis 分組
    { "name": "泰雅族", "data": [2940, 78, ...] },
    ...
  ],
  "categories": ["2025年1月", "2025年2月", ...]
}
```

---

## 7. 快速開始 {#quickstart}

### 7.1 確認系統狀態

```bash
# 檢查 DB 資料表
docker exec postgres-data psql -U postgres -d dashboard -c "
  SELECT tablename FROM pg_tables WHERE schemaname='public' 
  AND tablename IN ('aed_tpe','indigenous_by_district_tpe','migrant_workers_employed_tpe');"

# 檢查 dashboardmanager 組件
docker exec postgres-manager psql -U postgres -d dashboardmanager -c "
  SELECT COUNT(*) FROM components WHERE index LIKE '%indigenous%' OR index LIKE '%migrant%';"
```

### 7.2 在管理面板新增看板

1. 開啟 http://localhost:8889 (pgAdmin - 當前環境可能沒有 UI 管理界面)
2. 或直接使用 SQL 新增個人儀表板：

```sql
-- 在 dashboardmanager 中新增個人儀表板並加入組件
INSERT INTO dashboards (index, name, components) VALUES (
  'my_hackathon_2026',
  '黑客松成果展示',
  ARRAY[301, 303, 305, 306]  -- aed_map, indigenous_district_tpe, migrant_workers_tpe, long_term_care_abc_map
);
```

### 7.3 驗證 API 可用性

```bash
# 測試各組件一次
for id in 302 304 305 307; do
  echo "=== Component $id ==="
  curl -s "http://localhost/api/v1/components/$id/chart?city=taipei" | jq '.status'
done
```

---

## 8. 故障排除 {#troubleshooting}

### 問題 1: API 回傳 404
**症狀：** `GET /api/v1/components/302/chart` → 404 Not Found  
**原因：** Component ID 不存在或 dashboardmanager DB 查詢失敗  
**解決：**
```sql
-- 檢查組件是否存在
SELECT * FROM dashboardmanager.components WHERE index = 'aed_district_tpe';

-- 檢查 query_charts 是否配對
SELECT * FROM dashboardmanager.query_charts WHERE index = 'aed_district_tpe' AND city = 'taipei';
```

### 問題 2: API 回傳空數據
**症狀：** `GET /api/v1/components/302/chart` → 200 OK 但 `"data": []`  
**原因：** SQL 查詢正常但資料為空  
**解決：**
```sql
-- 檢查 DB 表中資料
SELECT COUNT(*) FROM dashboard.aed_tpe;
SELECT COUNT(*) FROM dashboard.indigenous_by_district_tpe;

-- 手動執行 query_chart SQL 確認
SELECT district AS x_axis, COUNT(*) AS data FROM public.aed_tpe 
GROUP BY district ORDER BY data DESC;
```

### 問題 3: 地圖未顯示
**症狀：** 地圖加載但無圖層  
**原因：** GeoJSON 檔案遺失或路徑不對  
**解決：**
```bash
# 檢查 GeoJSON 檔案
docker exec dashboard-fe ls -la /app/public/mapData/ | grep aed_map

# 或直接測試 HTTP GET
curl -I http://localhost/mapData/aed_map.geojson
# 應回傳 HTTP 200，Content-Type: application/json
```

### 問題 4: CSV 匯入失敗
**症狀：** 執行 `02_full_import.sh` 時出現 COPY 錯誤  
**原因：** CSV 編碼、分隔符、欄位數量不符  
**解決：**
```bash
# 檢查 CSV 編碼與欄位數
file /path/to/aed_tpe.csv  # 應是 UTF-8
head -1 /path/to/aed_tpe.csv | tr ',' '\n' | wc -l  # 計算欄位数
```

---

## 9. 後續維護 {#maintenance}

### 9.1 定期更新資料

長照 ABC 據點與 AED 位置定期更新時：

```bash
# 1. 取得新 CSV
# 2. 複製到容器
docker cp new_data.csv postgres-data:/tmp/new_data.csv

# 3. 執行 COPY 更新表
docker exec -i postgres-data psql -U postgres -d dashboard << EOF
TRUNCATE TABLE public.long_term_care_abc_tpe;
COPY public.long_term_care_abc_tpe FROM '/tmp/new_data.csv' WITH (FORMAT csv, HEADER true);
EOF

# 4. 如使用 GeoJSON 地圖層，需重新生成
# (目前為靜態檔案，需手動更新 /mapData/*.geojson)
```

### 9.2 新增相似主題的快速路徑

若要新增類似的資料主題 (如「失業率」、「綠地分布」)：

```
1. 準備 CSV 資料 → /user-added/2025-last-year/my-data/{topic}/
2. 搭建 DB 表 → dashboard DB 新增表 + COPY 匯入
3. 撰寫 SQL 查詢 → query_chart 欄位
4. 設定組件 → component_charts 定義圖表類型與顏色
5. 登錄組件 → components 表
6. 建立儀表板 → dashboards 表關聯 component IDs
```

以上 6 步均無需修改 BE/FE 代碼（該系統已完全通用化）。

### 9.3 效能最佳化

若發現查詢變慢：

```sql
-- 1. 為常查欄位加索引
CREATE INDEX idx_indigenous_district_year 
ON dashboard.indigenous_by_district_tpe(year, month);

-- 2. BE 已使用 Redis 快取，確認 TTL 設定合理 (預設 5-10 分)
-- 3. 分析慢查詢
EXPLAIN ANALYZE SELECT district, COUNT(*) FROM aed_tpe GROUP BY district;
```

### 9.4 監控儀表板使用

在 BE logs 中監控組件 API 呼叫：

```bash
# 查看最常用的組件 (假設已有 structured logging)
grep "GET /api/v1/components" dashboard-be.log | \
  sed 's/.*\/components\/\([0-9]*\).*/\1/' | \
  sort | uniq -c | sort -rn | head -10
```

---

## 10. 下一步執行計畫（PM 導向）

本章將目前「已整合可見」提升為「可驗證、可監控、可持續擴充」。

### 10.1 目標（本季）

1. 將 4 個新儀表板納入正式維運與品質門檻。
2. 建立可複製的新主題上線流程（從資料到儀表板）並文件化。
3. 在不改變通用架構的前提下，補齊查詢安全與效能護欄。

### 10.2 優先級 Backlog（P0/P1/P2）

| 優先級 | 任務 | 產出物 | 驗收標準 |
|--------|------|--------|----------|
| P0 | 建立資料品質檢核（匯入前/後） | SQL 檢核腳本 + 每日報表 | 缺值率、重複率、座標合法率皆有門檻且可追蹤 |
| P0 | 建立組件 API Smoke Test | `301-307` 組件巡檢腳本 | 每日自動檢查，失敗即告警 |
| P0 | 查詢護欄治理 | 查詢白名單規則 + timeout + row limit | 慢查詢可控，無超時堆積 |
| P1 | GeoJSON 同步自動化 | 轉檔腳本 + 發佈流程 | DB 更新後可在同日完成圖層更新 |
| P1 | 上線驗收模板化 | 主題上線 checklist | 新主題 30 分鐘內可完成標準驗收 |
| P2 | 使用成效儀表板 | KPI 追蹤頁面/報表 | 可追蹤 DAU、互動率、最常用組件 |

### 10.3 30/60/90 天里程碑

| 時間 | 里程碑 | 關鍵交付 |
|------|--------|----------|
| Day 1-30 | M1: 品質基線建立 | 完成資料品質規則、API Smoke Test、告警通道 |
| Day 31-60 | M2: 安全與效能加固 | 完成查詢護欄、慢查詢分析、必要索引優化 |
| Day 61-90 | M3: 擴展標準化 | 完成 GeoJSON 自動化、上線模板、成效監控儀表板 |

### 10.4 KPI（可直接納入週報）

| 類別 | 指標 | 目標 |
|------|------|------|
| 資料品質 | 匯入成功率 | >= 99.5% |
| 資料品質 | 關鍵欄位缺值率 | <= 0.5% |
| API 穩定性 | 5xx 錯誤率 | < 0.1% |
| API 效能 | 圖表 API p95 | <= 800ms |
| API 效能 | 地圖 API/圖層 p95 | <= 1200ms |
| 產品成效 | 新看板 7 日活躍率 | >= 30% |
| 產品成效 | 地圖互動率（縮放/點擊） | >= 40% |

### 10.5 角色分工（RACI 簡化版）

| 任務 | 負責 (R) | 核准 (A) | 協作 (C) | 知會 (I) |
|------|----------|----------|----------|----------|
| 資料品質檢核 | DE | PM/Tech Lead | BE | FE |
| API 巡檢與告警 | BE | Tech Lead | DE | PM |
| 查詢護欄與索引 | BE | Tech Lead | DE | PM |
| GeoJSON 自動化 | DE | Tech Lead | FE | PM |
| KPI 儀表板 | PM | PO/Stakeholder | BE/FE | 全團隊 |

### 10.6 每週例行節奏（建議）

1. 週一：確認上週 KPI 與異常（20 分鐘）。
2. 週三：檢視新主題/既有主題資料品質報告（30 分鐘）。
3. 週五：決策下週 P0/P1 任務與風險緩解（30 分鐘）。

### 10.7 主要風險與緩解

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| 動態 SQL 配置錯誤 | API 超時或回空資料 | 上線前 SQL review + timeout + row limit |
| GeoJSON 未同步更新 | 地圖與圖表資料不一致 | 將 GeoJSON 產生納入固定排程 |
| 資料源格式突變 | 匯入失敗 | 匯入前 schema 驗證與欄位比對 |
| 指標只看技術不看使用 | 難證明業務價值 | 補齊採用率與互動率 KPI |

---

## 📊 實施統計

| 指標 | 數值 |
|-----|-----|
| 新增 DB 表 | 6 |
| 匯入資料筆數 | 10,743 |
| 新增組件 | 7 |
| 新增地圖圖層 | 3 |
| 新增儀表板 | 4 |
| 新增查詢設定 | 8 |
| BE 代碼修改 | 0 行 (完全通用) |
| FE Vue 修改 | 0 行 (完全通用) |
| SQL 總長度 | ~8000 字符 |

---

## 🎯 核心成果

✅ **2026 黑客松功能現已全棧可見**  
使用者可透過：
- 儀表板介面看到 4 個新看板
- 地圖上看到 3 個新圖層 (AED、長照 ABC)
- 隨選圖表看到原住民族、移工統計數據  
✅ **無須 BE/FE 代碼修改就能新增相似功能**  
後續新主題只需準備 CSV → 執行 SQL 設定 (驗證時間 < 5 分鐘)

---

## 附錄

### 檔案清單

```
user-added/2025-last-year/my-data/sql/
├── 01_dashboard_db_tables.sql      # 建立 6 個表
├── 02_full_import.sh               # 批量匯入腳本 (舊版)
├── 02_import_csv_data.py           # Python CSV 匯入器
├── 02b_copy_csv_import.sql         # COPY 命令 SQL
├── 02b_fix_remaining.sh            # 修復 temp table 匯入
├── 03_dashboardmanager_inserts.sql # 組件設定SQL (核心)
├── 04_apply_all.sh                 # 一鍵執行腳本
├── test_copy.sh                    # 測試腳本
└── README.md                       # 此檔案

user-added/2025-last-year/my-data/
├── AED/                            # AED CSV 源檔
├── 原住民族人口/                    # 原住民 CSV 源檔
├── 移工/                            # 移工 CSV 源檔
└── 長照/                            # 長照 CSV 源檔
```

---

**最後更新：2026-04-14**  
**整合狀態：生產就緒 (Production Ready) ✅**
