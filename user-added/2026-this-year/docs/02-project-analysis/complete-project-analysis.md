# Taipei-City-Dashboard 專案完整分析 (2026)

日期: 2026-04-14
範圍: FE + BE + DE + Docker/Helm + user-added 歷史資產

## 1. 專案目標與定位

Taipei-City-Dashboard 是以政策決策與公眾資訊揭露為核心的城市資料視覺化平台，採用三層分工:
- FE: 呈現儀表板、圖表、地圖互動
- BE: API、認證、資料聚合、快取
- DE: Airflow ETL 管線、資料清洗與入庫

你的 2026 工作重點是:
- 整併去年黑客松成果
- 做官方主線對照
- 盤點可上線主題與差異化題材

## 2. 系統架構摘要

### FE (`Taipei-City-Dashboard-FE`)
- 技術: Vue 3 + Vite
- 重點路徑: `src/components`, `src/dashboardComponent`, `public/mapData`
- 角色: 視覺化與互動層

### BE (`Taipei-City-Dashboard-BE`)
- 技術: Go + GORM + Redis
- 重點路徑: `app/controllers`, `app/services`, `app/models`
- 角色: API 與業務規則

### DE (`Taipei-City-Dashboard-DE`)
- 技術: Airflow DAG
- 重點路徑: `dags/proj_city_dashboard`, `dags/proj_new_taipei_city_dashboard`
- 角色: 資料抽取、轉換、載入

### Infra
- Docker Compose + Helm Chart
- 角色: 本地開發、SIT/Prod 部署一致性

## 3. 2026 前後的核心變化

1. `develop` 已對齊官方 `upstream/develop`
2. 你的歷史分支 `origin/codefest/4j/qavit` 已能合併至 `develop`
3. Git 文字衝突為 0，但仍有功能重疊風險

## 4. 功能覆蓋與差異化

### 官方已有較完整覆蓋
- AED
- 長照
- 老人
- 學校/學區

### 你方具差異化潛力
- 原住民人口
- 新住民/移工
- 垃圾清運

## 5. 主要風險

1. 語意衝突: 同主題資料口徑不一致
2. 流程重複: 同功能多份腳本與 GeoJSON
3. 維運成本: 非標準 DE 腳本難以長期維護

## 6. 機會點

1. 以差異化主題快速上線，建立可見成果
2. 建立主題資料契約，降低跨組溝通成本
3. 將個人資產標準化到 DE DAG，轉為可維運能力

## 7. 建議策略

### P0 (本週)
1. 鎖定上線主題: 原住民/移工/垃圾
2. 製作主題對照表 (來源/欄位/更新頻率/主鍵)
3. 凍結重疊主題 (AED/長照/老人/學區) 的新改動

### P1 (1-2 週)
1. 將差異化主題轉為 DE DAG
2. 補齊資料品質檢核與錯誤告警
3. 規範 FE 圖層命名與資料來源標記

### P2 (2-4 週)
1. 重疊主題 A/B 比對後選單一主版
2. 建置每月資料品質報告

## 8. 驗收條件

1. 每個新主題至少 1 條穩定 DAG
2. FE 可成功載入對應圖層與指標
3. 缺值率、重複率、座標合法率達標
4. 文件可追溯: 來源、版本、決策都有記錄

## 9. 結論

2026 最具投資報酬的策略不是全量重做，而是:
- 先以差異化主題交付可見成果
- 同步推動標準化與資料契約
- 對重疊主題做治理而非疊加

這樣可以在最短時間內，同時達成「上線速度」與「長期可維運」。
