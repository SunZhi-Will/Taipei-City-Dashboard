---
name: data-theme-integration
description: "Use when: 擴充新資料主題（如社會福利、教育、健康、環保、經濟）；端對端整合：資料收集→轉換→BE API→FE 組件；支援全棧開發，優先級與成本評估。適用於黑客松課題、政策資料新增。"
applyTo: "**"
---

# 資料主題擴充與全棧整合 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 需求評估 | 主題定義、資料源評估、ROI 分析 | 決策文件通過 | P0 |
| M2: 端對端實現 | DE → BE → FE 完整集成 | 3 個組件可用 | P1 |
| M3: 資料品質 | 驗證、測試、文件化、使用者測試 | 90% 資料正確率 | P1 |
| M4: 發佈與監控 | 導入、監控告警、使用者反饋 | DAU >100 | P2 |

---

## 🎯 主題評估框架

### 社會福利主題（範例）
```
主題: 長照據點 (Long-term Care)
├─ 必要性評分: 10/10 (銀髮族關鍵需求)
├─ 資料可取得性: 高 (政府開放資料)
├─ 實作複雜度: 中 (地理位置、服務類別)
├─ 使用者基數: 百萬長照人口 + 子女/照護者
├─ 政策關聯: 長照 2.0 計畫，與市政策對齐
└─ 預期 ROI: 高 (提升照護效率、知情選擇)
```

### 主題選擇清單
| 主題 | 領域 | 資料源 | 複雜度 | 優先級 |
|------|------|--------|--------|--------|
| AED (自動體外除顫器) | 健康 | 消防局 API | 低 | P0 |
| 原住民人口 | 社會 | 統計處、民政局 | 中 | P0 |
| 新住民/移工 | 社會 | 勞動局、移民署 | 中 | P1 |
| 老人福利設施 | 福利 | 社會局 | 中 | P0 |
| 學校/學區 | 教育 | 教育局 | 低 | P1 |
| 垃圾清運 | 環保 | 環保局 | 中 | P1 |
| 失業率/薪資 | 經濟 | 統計處 | 低 | P2 |

---

## 🔄 全棧工作流程

### Phase 1: 需求與資料探索
```
1. 主題定義與業務需求
   ├─ 誰是使用者？ (政策制定者、公眾、特定族群)
   ├─ 使用場景？ (尋找服務、政策決策、學術研究)
   ├─ 核心指標？ (分佈、趨勢、對比)
   ├─ 互動需求？ (篩選、搜尋、地圖、時間軸)
   └─ 成功指標？ (訪問量、停留時間、反饋評分)

2. 資料源評估
   ├─ 識別 3~5 個資料源 (主要 + 備用)
   ├─ 資料更新頻率 (日/週/月/季)
   ├─ 許可證檢查 (CC0, CC-BY, 專有)
   ├─ API vs 下載方式評估
   ├─ 資料完整性檢查 (覆蓋範圍、欄位)
   └─ 成本評估 (爬蟲成本、API 配額)

3. Schema 與資料字典
   ├─ 關鍵欄位定義 (id, name, category, location, metrics)
   ├─ 資料型別與驗證規則
   ├─ 隱私檢查 (個資脫敏)
   ├─ 座標系統確認
   └─ 更新策略 (append, upsert, replace)
```

### Phase 2: 資料工程 (Airflow DAG)
```
4. 設計 ETL 管道
   ├─ 資料來源連線 (API credentials, 檔案路徑)
   ├─ 抓取頻率與 SLA (每日凌晨2點)
   ├─ 增量邏輯 (last_modified, checksum)
   ├─ 臨時表管理
   └─ 備份與回復策略

5. 實現轉換邏輯 (Python/SQL)
   ├─ 資料清理 (缺失值、異常值、重複)
   ├─ 地理編碼 (地址→座標: Nominatim, Google Geocoding)
   ├─ 資料豐化 (合併相關維度表、計算衍生指標)
   ├─ 格式標準化 (時間、編碼值)
   └─ 品質檢查 (行數驗證、統計檢查)

6. DAG 佈署
   ├─ 檔案位置: dags/proj_city_dashboard/[theme_name]/
   ├─ 命名慣例: [theme_name]_[source]_dag.py
   ├─ 排程表達式設定
   ├─ Dry run 驗證
   └─ 監控告警配置

   範例目錄結構:
   dags/proj_city_dashboard/
   ├─ long_term_care/
   │  ├─ long_term_care_tpe_dag.py
   │  ├─ transform_long_term_care.py
   │  └─ config.yaml
   └─ indigenous/
      ├─ indigenous_population_dag.py
      └─ ...
```

### Phase 3: 後端 API (Go)
```
7. 設計 API 端點
   ├─ 列表端點: GET /api/v1/[resource]
   │   ├─ 分頁 (page, limit)
   │   ├─ 篩選 (category, district, date_range)
   │   ├─ 排序 (by name, by distance, by date)
   │   └─ 回應格式標準化
   ├─ 詳情端點: GET /api/v1/[resource]/{id}
   ├─ 統計端點: GET /api/v1/[resource]/stats
   │   ├─ 按行政區計數
   │   ├─ 時間序列趨勢
   │   └─ 相關性分析
   ├─ 搜尋端點: GET /api/v1/[resource]/search?q=...
   └─ 地理查詢: GET /api/v1/[resource]/within-bounds?bbox=

8. 實現 Model + Service
   ├─ Model 定義 (app/models/[theme].go)
   │   ├─ 資料庫表結構
   │   ├─ JSON serialization tags
   │   └─ 驗證約束
   ├─ Repository 層 (app/services/)
   │   ├─ GORM 查詢邏輯
   │   ├─ 索引策略
   │   └─ 快取層
   └─ Business Logic Service
       ├─ 統計計算
       ├─ 地理空間查詢
       └─ 資料豐化

9. 實現 Controller
   ├─ 路由註冊 (app/routes/)
   ├─ 請求驗證
   ├─ 響應格式化
   ├─ 錯誤處理
   └─ 日誌與指標

   範例路由:
   GET /api/v1/long-term-care
   GET /api/v1/long-term-care/{id}
   GET /api/v1/long-term-care/search
   GET /api/v1/long-term-care/stats/by-district
```

### Phase 4: 前端組件 (Vue 3)
```
10. 組件設計與開發
    ├─ 列表視圖 (表格 + 分頁)
    ├─ 卡片視圖 (簡潔資訊展示)
    ├─ 地圖視圖 (整合 Mapbox + Deck.gl)
    ├─ 統計圖表 (按行政區分佈、趨勢)
    ├─ 詳情頁面 (側邊欄或 modal)
    └─ 篩選面板 (類別、時間、位置)

11. 狀態管理 (Pinia Store)
    ├─ 資料快取 (items, selected filters)
    ├─ 載入狀態 (loading, error)
    ├─ 分頁狀態 (current page, total)
    └─ 使用者偏好 (星標、視圖類型)

12. 整合到儀表板
    ├─ 新增儀表板組件定義
    ├─ 拖曳 layout 配置
    ├─ 組件間通訊 (cross-filter)
    ├─ 深連結支援 (URL state)
    └─ 分享功能 (社交媒體、郵件)
```

---

## 💡 技術決策樹

### 資料源選擇
```
是否有官方 API？
├─ 是 → 使用 API (最佳)
│  ├─ 實時性強
│  └─ 易於自動化
└─ 否 → 評估替代方案
   ├─ 政府開放資料下載 (次佳)
   ├─ 第三方 API (考慮成本/授權)
   └─ 爬蟲 (最後手段, 檢查合法性)
```

### 地理編碼選擇
| 來源 | 精準度 | 成本 | 用途 |
|------|--------|------|------|
| 內部 DB (地址→座標預先對應) | 高 | 無 | 主流 |
| Google Geocoding API | 高 | 收費 | 備用/驗證 |
| Nominatim (OSM) | 中 | 免費 | 原型/備用 |

---

## 🛡️ 實踐檢查清單

### 資料工程
- [ ] 資料源負責人與聯絡方式已記錄
- [ ] DAG dry run 成功，無遺漏記錄
- [ ] 品質檢查告警已配置
- [ ] GeoJSON 輸出已驗證 (geojsonhint)
- [ ] 備份/回復計畫已測試

### 後端
- [ ] Controller + Model + Service 單元測試 >80%
- [ ] API 文檔已寫 (Swagger 或 README)
- [ ] 效能基準測試通過 (<200ms)
- [ ] 資料庫索引已最佳化 (EXPLAIN ANALYZE)
- [ ] 快取失敗不導致功能破壞

### 前端
- [ ] 所有組件已響應式測試 (mobile/desktop)
- [ ] 組件無障礙檢查通過 (axe-core)
- [ ] 加載大數據 (>10k) 流暢度正常
- [ ] SEO 元素已補全 (頁面 title, meta 描述)
- [ ] 分享功能已測試 (Facebook, Line, Email)

### 整體
- [ ] 使用者驗收測試通過
- [ ] 部署檢查清單已完成
- [ ] 監控告警已啟用
- [ ] Runbook 與常見問題已文件化
- [ ] 微量帳戶資料已脫敏

---

## 📋 主題擴充範例：AED 資料

**資料來源**: 台北市消防局 API  
**更新頻率**: 週三  
**API 端點**:
```
GET /api/v1/aed
  ?district=松山&sort=distance&lat=25.05&lon=121.56
```

**FE 組件**:
- 地圖層 (紅色標記)
- 列表視圖 (距離排序)
- 詳情卡 (地址、電話、使用指南)
- 統計 (台北市 X 台 AED, 距離分佈)

**BE Model**:
```go
type AED struct {
    ID        uint
    Name      string
    Address   string
    Latitude  float64
    Longitude float64
    District  string
    Phone     string
    UpdatedAt time.Time
}
```

---

## 📚 參考檔案

- **DE 黑客松例子**: [analysis/2026-04-14_hackathon_update_analysis.md](../analysis/2026-04-14_hackathon_update_analysis.md)
- **BE Model 範例**: [Taipei-City-Dashboard-BE/app/models/](../Taipei-City-Dashboard-BE/app/models/)
- **FE 組件範例**: [Taipei-City-Dashboard-FE/src/dashboardComponent/](../Taipei-City-Dashboard-FE/src/dashboardComponent/)
- **DAG 範例**: [Taipei-City-Dashboard-DE/dags/proj_city_dashboard/](../Taipei-City-Dashboard-DE/dags/proj_city_dashboard/)
