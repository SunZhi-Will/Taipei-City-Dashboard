# 2026 Hackathon 專案更新與歷史修改分析報告

日期: 2026-04-14
分析者: GitHub Copilot (GPT-5.3-Codex)

## 1. 執行摘要

本次已完成兩件事:
1. 你的 `develop` 已同步官方 `upstream/develop`，並推送到你的 `origin/develop`。
2. 追溯你去年黑客松的「個人修改」，確認主要集中在 `origin/codefest/4j/qavit` 分支 (27 個你方獨有 commit)。

關鍵結論:
- 你去年主要做的是「資料主題擴充 + 轉換腳本 + GeoJSON 產出 + 文件/筆記」，而非大幅改動核心 FE/BE 程式邏輯。
- 官方目前已新增部分同主題資料流程 (AED、長照、老人、學校相關)，但「原住民、新住民/移工、垃圾清運」在官方主線中未看到明確對應檔案。
- 若現在把 `origin/codefest/4j/qavit` 直接合併回目前 `develop`，實測 `CONFLICT_COUNT=0`，可合併，但需做語意層去重。

---

## 2. 分析範圍與基準

分支基準:
- BASE (共同祖先): `4585a28b71d4fd4b498f9eebd81723824f070e57`
- 目前 develop: `0f81d3b1`
- 你的歷史分支: `origin/codefest/4j/qavit` (`85affaeb`)
- 官方主線: `upstream/develop` (`0f81d3b1`)

比較邏輯:
1. 你去年修改: `upstream/develop..origin/codefest/4j/qavit` 的專屬 commit。
2. 官方是否有新增同類資料: 以官方分支檔案路徑關鍵字檢查 (AED/long_term/indigenous/migrant/elderly/school/garbage)。
3. 衝突檢查: 在臨時分支進行 `merge --no-commit --no-ff` 實測。

---

## 3. 你去年修改了什麼 (功能導向)

以下是從 27 個專屬 commit 與實際變更路徑彙整出的功能清單:

### A. AED 資料管線
- 新增台北/新北 AED 資料整理流程。
- 新增地址轉座標 (Nominatim) 與 geocache、錯誤記錄。
- 新增資料說明與匯入筆記。

依據 (commit 範例):
- `46a8ed47` feat: add AED and garbage collection datasets
- `059e1122` feat: 新增台北市AED資料轉換腳本
- `09449577` feat: 使用 Nominatim 轉座標
- `f420ce89` feat: 新增新北市 AED 轉換腳本

依據 (路徑範例):
- `my-data/AED/transform_aed_tpe.py`
- `my-data/AED/transform_aed_ntpc.py`
- `my-data/AED/get_coord_from_addr.py`
- `my-data/AED/aed.md`

### B. 原住民族人口資料
- 新增多種原住民人口資料集 (依行政區、依族別、依年齡等)。
- 新增跨年度整併與資料轉換腳本。
- 多次調整目錄命名與結構。

依據 (commit 範例):
- `07127f7e` feat: add indigenous peoples datasets
- `bbbd839c` feat: 新增臺北市原住民人口統計資料轉換腳本
- `cda9be38` feat: 新增臺北市原住民人口統計資料（依民族別）
- `e92eae66` feat: 新增原住民資料轉換腳本及統計結果
- `51dfe268` feat: 新增 9 個原住民、新住民資料集

依據 (路徑範例):
- `my-data/.../by_district_TPE_transformer.py`
- `my-data/.../by_group_TPE_transformer.py`
- `my-data/.../indigenous_population.md`

### C. 新住民 / 移工資料
- 新增雙北受聘僱移工資料與轉換腳本。

依據:
- `36706dd2` feat: 新增雙北受聘僱移工資料及腳本
- 路徑: `my-data/.../transform_migrant_workers_employed.py`

### D. 長照資料與地圖輸出
- 新增長照資料與處理腳本。
- 產出長照地圖資料 (GeoJSON)。
- 補充 SQL 與分析筆記。

依據:
- `5ecf2191` feat: 新增長照資料
- `4a5a441b` feat: 新增長照據點資料轉換腳本
- `015a270b` feat: 新增長照處理腳本、SQL筆記、GeoJSON
- `35937abc` feat: 做完 1 個長照據點組件，含地圖

依據 (路徑範例):
- `my-data/長照/process_abc_data.py` (路徑含中文資料夾)
- `Taipei-City-Dashboard-FE/public/mapData/long_term_care_abc_tpe.geojson`
- `Taipei-City-Dashboard-FE/public/mapData/long_term_care_abc_metrotaipei.geojson`

### E. 老人 / 學區等補充資料
- 老人分布與老人福利機構更新。
- 學區數量相關資料。

依據:
- `0c48259f` 老人分佈
- `5348711a` feat: 更新老人福利機構
- `6a31d53d` 學區數量

### F. 工程化與交付支援
- 新增資料清單、SQL/Postgres 筆記。
- 新增資料庫備份檔。
- 新增 Go CI (golangci-lint) 與環境設定調整。

依據:
- `509c5f2e` feat: add dataset lists
- `6c91dd3d` docs: 新增 Postgres 筆記
- `ac1597fd` add go ci
- 路徑: `.github/workflows/golangci-lint.yml`, `my-data/pg-note.md`, `my-data/backup_dashboard.sql`

---

## 4. 官方目前是否已新增這些資料主題

比對結果 (依官方 `upstream/develop` 檔名關鍵字):

1. AED: 有
- 證據路徑:
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/aed_locations/aed_locations.py`
  - `Taipei-City-Dashboard-DE/dags/proj_new_taipei_city_dashboard/aed_locations/aed_locations.py`

2. 長照 (long_term): 有
- 證據路徑:
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/long_term/long_term.py`
  - `Taipei-City-Dashboard-DE/dags/proj_new_taipei_city_dashboard/long_term/long_term.py`

3. 老人 (elderly): 有
- 證據路徑:
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/elderly_club/elderly_club.py`
  - `Taipei-City-Dashboard-DE/dags/proj_new_taipei_city_dashboard/elderly_club/elderly_club.py`

4. 學校/學區: 有
- 證據路徑:
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/D090101_1/school_dist_etl.py`
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/D090101_2/vil_of_school_dist_etl.py`
  - `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/school_reconstruction/school_reconstruction.py`

5. 原住民 (indigenous): 目前未找到明確對應檔名
- 關鍵字檢索 count: 0

6. 新住民/移工 (migrant/foreign_workers/new_immigrant): 目前未找到明確對應檔名
- 關鍵字檢索 count: 0

7. 垃圾清運 (garbage): 目前未找到明確對應檔名
- 關鍵字檢索 count: 0

判讀:
- 官方已覆蓋你部分主題 (AED/長照/老人/學校)。
- 你去年做的原住民、新住民/移工、垃圾清運仍可能是可補位的差異化資產。

---

## 5. 是否有衝突

### 檔案層衝突風險
- 共同基準後雙方變更檔案交集: 1 檔
- 交集檔案: `.gitignore`

### 實際合併測試
- 測試方式: 從 `develop` 開臨時分支 `audit/merge-check`，執行 `merge --no-commit --no-ff origin/codefest/4j/qavit`
- 結果: `CONFLICT_COUNT=0`
- 結論: Git 層面可直接合併，不會卡文字衝突。

### 但仍有「語意衝突」風險
- 雖然沒有 Git 衝突，但在主題上可能會重複:
  - AED
  - 長照
  - 老人
  - 學校
- 建議做資料品質與口徑比對，避免同主題重複上線或指標定義不一致。

---

## 6. 顧問建議 (可執行)

### 優先級 P0 (本週)
1. 先不整包合併 `codefest/4j/qavit`，改做主題分批挑選。
2. 針對官方未覆蓋主題先提案: 原住民、新住民/移工、垃圾清運。
3. 建立資料契約比對表 (來源、更新頻率、欄位定義、主鍵、地理欄位)。

### 優先級 P1 (1-2 週)
1. 把你既有轉換腳本轉成 DE DAG 標準結構。
2. 補上驗證規則: 去重、缺值、座標有效性、行政區映射。
3. 產出對應 dashboard component 規格與驗收標準。

### 優先級 P2 (2-4 週)
1. 與官方既有 AED/長照/老人主題整併，保留品質較高版本。
2. 完成回歸測試與上線前資料比對報表。

建議 KPI:
- 新主題成功上線數
- 資料更新成功率
- 資料品質錯誤率
- 地圖點位可解析率

---

## 7. 本報告依據來源 (可追溯)

關鍵 Git 指令類型:
1. 分支差異與共同祖先
2. 專屬 commit 清單 (`upstream/develop..origin/codefest/4j/qavit`)
3. 路徑交集計算 (雙方變更檔案集合交集)
4. 官方關鍵字路徑檢索
5. 臨時分支合併衝突測試

備註:
- 官方是否「有新增同主題」是用官方檔名關鍵字與路徑結構判讀；若需更高精度，可再進一步做欄位級 SQL 與 ETL 邏輯比對。
