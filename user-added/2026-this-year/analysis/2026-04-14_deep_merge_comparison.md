# 深層分析與交互檢測報告 (2026-04-14)

## A. 本次已完成事項

1. 已將官方更新整併至你的 develop (先前已完成)。
2. 已將你去年分支 `origin/codefest/4j/qavit` 正式合併到 `develop`。
3. 已完成交互檢測: 你做的功能 vs 官方已做功能。
4. 已完成衝突檢查: Git 文字衝突與語意層重疊風險分開判讀。

合併事實:
- 合併提交: `ae8391bd`
- 合併策略: `ort`
- Git 衝突: 0
- 目前分支狀態: `develop` ahead `origin/develop` 28 commits (尚未推送)

---

## B. 分析基準與依據

基準點:
- 共同祖先: `4585a28b71d4fd4b498f9eebd81723824f070e57`
- 官方基準: `upstream/develop` (`0f81d3b1`)
- 你的歷史分支: `origin/codefest/4j/qavit` (`85affaeb`)

依據來源:
1. 你方專屬提交數: `27` commits (`upstream/develop..origin/codefest/4j/qavit`)
2. 你方變更檔案數: `248` files (`base..user`)
3. 官方主線主題覆蓋: 由 `upstream/develop` 全樹關鍵字檢索
4. 真實合併測試與實際合併結果

---

## C. 你去年做的功能 (功能導向)

### 1) AED 資料流
- 台北/新北 AED 原始資料整理
- 地址轉座標 (Nominatim)
- geocache 與錯誤紀錄
- FE 地圖圖層輸出 (GeoJSON)

證據:
- commit: `46a8ed47`, `059e1122`, `09449577`, `f420ce89`
- path sample:
  - `my-data/AED/transform_aed_tpe.py`
  - `my-data/AED/transform_aed_ntpc.py`
  - `my-data/AED/get_coord_from_addr.py`
  - `Taipei-City-Dashboard-FE/public/mapData/aed_map.geojson`

### 2) 長照資料流
- 長照資料清理與整併
- 行政區映射與處理腳本
- SQL 與分析筆記
- FE 長照圖層輸出

證據:
- commit: `5ecf2191`, `4a5a441b`, `015a270b`, `35937abc`
- path sample:
  - `my-data/長照/process_abc_data.py`
  - `my-data/長照/long_term_care_abc_sql.md`
  - `Taipei-City-Dashboard-FE/public/mapData/long_term_care_abc_tpe.geojson`

### 3) 原住民資料流
- 原住民人口資料集建置 (行政區/族別/年齡)
- 跨年度彙整與轉換腳本

證據:
- commit: `07127f7e`, `bbbd839c`, `cda9be38`, `e92eae66`, `51dfe268`
- path sample:
  - `my-data/原住民族人口/by_district_TPE_transformer.py`
  - `my-data/原住民族人口/by_group_TPE_transformer.py`

### 4) 新住民/移工資料流
- 雙北受聘僱移工資料
- 轉換腳本與說明

證據:
- commit: `36706dd2`
- path sample:
  - `my-data/移工/transform_migrant_workers_employed.py`

### 5) 老人、學區、垃圾清運補充資料
- 老人福利與分布資料
- 學區資料
- 垃圾清運地圖資料

證據:
- commit: `0c48259f`, `5348711a`, `6a31d53d`, `46a8ed47`
- path sample:
  - `sun-data/process_elderly_care_data.py`
  - `sun-data/school.sql`
  - `Taipei-City-Dashboard-FE/public/garbage_collection_points.geojson`

---

## D. 官方 vs 你方 功能交互檢測

主題矩陣 (關鍵字路徑命中數):

| 主題 | 你方命中 | 官方命中 | 判讀 |
|---|---:|---:|---|
| AED | 10 | 6 | 雙方皆有，需做品質/欄位口徑比對 |
| 長照 long_term | 5 | 6 | 雙方皆有，需去重整併 |
| 老人 elderly | 1 | 6 | 雙方皆有，官方較完整 |
| 學區 school | 1 | 5 | 雙方皆有，官方已有既定管線 |
| 原住民 indigenous | 1 | 0 | 你方差異化優勢 |
| 新住民/移工 migrant | 4 | 0 | 你方差異化優勢 |
| 垃圾清運 garbage | 1 | 0 | 你方差異化優勢 |

官方已存在樣本:
- `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/aed_locations/aed_locations.py`
- `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/long_term/long_term.py`
- `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/elderly_club/elderly_club.py`
- `Taipei-City-Dashboard-DE/dags/proj_city_dashboard/D090101_1/school_dist_etl.py`

你方樣本:
- `my-data/AED/transform_aed_tpe.py`
- `my-data/移工/transform_migrant_workers_employed.py`
- `Taipei-City-Dashboard-FE/public/garbage_collection_points.geojson`

---

## E. 衝突與整併風險分析

### 1) Git 衝突 (文字層)
- 結果: 無衝突。
- 實測與正式合併均通過。

### 2) 語意衝突 (功能層)
- 高風險重複主題: AED、長照、老人、學區。
- 風險型態:
  1. 指標口徑不同 (同名欄位不同定義)
  2. 更新頻率不同 (批次週期不一致)
  3. 主鍵策略不同 (重複點位/重複機構)
  4. 前端圖層重複 (相同主題多份 GeoJSON)

### 3) 結構風險
- 你方合併帶入大量資料與文件，含 `Taipei-City-Dashboard-Documentation/` 與 `my-data/`。
- 需決定哪些屬於產品正式資產，哪些屬於研究/備份資產。

---

## F. 建議整併策略 (顧問版)

### P0 (立即，本週)
1. 鎖定正式上線範圍: 只保留「產品必需」資料與腳本。
2. 建立主題對照表 (官方管線 vs 你方資產):
   - 資料來源
   - 欄位 schema
   - 更新頻率
   - 主鍵規則
3. 先推差異化主題: 原住民、新住民/移工、垃圾清運。

### P1 (1-2 週)
1. 將你方腳本改造成 DE DAG 規格。
2. 增加資料品質檢核:
   - 座標合法率
   - 去重率
   - 缺值率
   - 行政區映射成功率
3. 前端圖層命名與來源欄位標準化，避免重複圖層。

### P2 (2-4 週)
1. 對重疊主題做 A/B 比對，選出唯一主版。
2. 補回歸測試與每月品質報告。

---

## G. 建議 KPI

1. 差異化主題上線數 (原住民/移工/垃圾)
2. 資料管線成功率 (DAG success rate)
3. 地圖點位有效率
4. 口徑一致性指標 (欄位比對通過率)
5. 重複圖層清理完成率

---

## H. 下一步執行建議

1. 先推送目前合併結果到遠端:
- `git push origin develop`

2. 建立「主題整併白名單」(建議先做):
- 保留: 原住民、新住民/移工、垃圾清運
- 待比對再決策: AED、長照、老人、學區

3. 我可以下一輪直接幫你做:
- 產出一份可執行整併清單 (逐檔案/逐腳本)
- 附上每項驗收標準與風險緩解
