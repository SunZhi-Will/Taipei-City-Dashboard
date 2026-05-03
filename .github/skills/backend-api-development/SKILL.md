---
name: backend-api-development
description: "Use when: 開發 Go 後端 API、新增 Controllers、Models、Services；實作 JWT 認證、資料驗證、錯誤处理；優化 GORM 查詢和 Redis 快取策略。適用於新功能 endpoint、資料層擴充、效能調優。"
applyTo: "Taipei-City-Dashboard-BE/**"
---

# 後端 API 開發 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 設計與審查 | API 規格確認、DB Schema 設計 | 0 breaking changes | P0 |
| M2: 實現 Core Logic | Controller + Model + Service | 90% 單元測試涵蓋率 | P0 |
| M3: 快取與效能 | Redis 集成、查詢優化 | <200ms 平均響應時間 | P1 |
| M4: 安全與監控 | JWT 驗證、錯誤日誌、指標 | 100% 稽核事件記錄 | P1 |

---

## 🔄 工作流程

### Phase 1: 需求分析與設計
```
1. 確認業務需求
   ├─ 用戶故事：Who → What → Why
   ├─ 資料模型：領域實體、關係、制約
   └─ API Contract：HTTP 方法/路由、Request/Response 格式

2. 檢查現有架構
   ├─ 是否有類似 Controller (ai.go / dashboard.go)
   ├─ 複用 Service 層邏輯
   └─ 確認 Model 與 DB 表映射
```

### Phase 2: 實現 Model + Repository
```
3. 新增 GORM Model (app/models/)
   ├─ 定義 struct，注解 gorm.Model, json tags
   ├─ 增設 DB 索引（complex queries）
   └─ 產生 Migration 或手動 SQL

4. 實現 Service/Repository 層 (app/services/)
   ├─ 封裝業務邏輯（不直接操作 DB）
   ├─ 返回 error, 不 panic
   └─ 支援 context timeout
```

### Phase 3: 實現 Controller 與路由
```
5. 新增 Controller (app/controllers/)
   ├─ 接收 *gin.Context
   ├─ 呼叫 Service，轉換 response
   ├─ 統一錯誤處理（c.JSON(http.StatusXXX, errResp)）
   └─ 驗證 input params, headers, body

6. 註冊路由 (app/routes/)
   ├─ Group by prefix (/api/v1/resource)
   ├─ 設定 Middleware (auth, logging)
   └─ 支援 rate-limit
```

### Phase 4: 快取、安全、監控
```
7. 整合 Redis 快取 (app/cache/)
   ├─ Invalidation strategy（TTL vs event-driven）
   ├─ Serialization 格式 (JSON, msgpack)
   └─ 檢查 stampede 防禦

8. 加強安全
   ├─ ValidateJWT token (app/middleware/auth.go)
   ├─ Input sanitization (SQLi, XSS 防禦)
   └─ Rate limit per user/IP

9. 新增日誌和指標
   ├─ Structured logging (app/logs/)
   ├─ Prometheus 指標 (p8s 標籤: endpoint, status)
   └─ Trace correlation ID
```

---

## 💡 技術決策點

### 🔐 認證與授權
**決策**: JWT vs Session  
✅ **選定**: JWT（無狀態，適合微服務；與 WebSocket 相容）  
- Token 在 Authorization header  
- Claims 含 user_id, role, exp  
- Refresh token 存 Redis (24h TTL)

### 📦 快取策略
| 情境 | 模式 | TTL |
|------|------|-----|
| 靜態參考資料（行政區、族別代碼） | Cache-Aside | 7天 |
| 即時儀表板資料 | Invalidate on write | 5分鐘 |
| 使用者個人資訊 | Write-through | 1小時 |

### 🗄️ 資料庫層
**複用 GORM 超時策略**:
```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
db.WithContext(ctx).Find(&results)
```

### 🎯 錯誤回應統一格式
```json
{
  "code": "RESOURCE_NOT_FOUND",
  "message": "Dashboard ID 123 not found",
  "details": { "dashboard_id": 123 }
}
```

---

## 🛡️ 實踐檢查清單

- [ ] API 路由文件化 (Swagger spec 或 README)
- [ ] 單元測試涵蓋 >80% (mocking Service 層)
- [ ] 整合測試涵蓋關鍵路徑 (e2e test fixtures)
- [ ] 驗證 JWT middleware 在所有保護路由上
- [ ] Redis key naming convention 文件化
- [ ] Logging 包含 request_id, user_id, timestamp
- [ ] 監控儀表板已設定 (response time SLO)
- [ ] Changelog 記錄 breaking changes
- [ ] 資料庫遷移腳本已測試（rollback 計畫）
- [ ] 效能基準測試通過（p99 <500ms）

---

## 📚 參考檔案

- **Models**: [app/models/](../Taipei-City-Dashboard-BE/app/models/)
- **Controllers**: [app/controllers/](../Taipei-City-Dashboard-BE/app/controllers/)
- **Routes**: [app/routes/](../Taipei-City-Dashboard-BE/app/routes/)
- **Auth Middleware**: [app/middleware/auth.go](../Taipei-City-Dashboard-BE/app/middleware/auth.go)
- **Cache**: [app/cache/redis.go](../Taipei-City-Dashboard-BE/app/cache/redis.go)
