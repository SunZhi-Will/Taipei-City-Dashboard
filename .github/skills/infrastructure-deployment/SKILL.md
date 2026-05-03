---
name: infrastructure-deployment
description: "Use when: 部署與管理容器化基礎設施，使用 Docker/Docker Compose、Kubernetes、Helm Chart；配置 PostgreSQL、Redis、Qdrant；監控與擴展（HPA、負載均衡）。適用於環境建置、CI/CD 配置、生產升級。"
applyTo: "docker/**,helm-chart/**"
---

# 基礎設施與容器化部署 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 容器化設計 | Dockerfile 優化、多階段構建 | 映像大小 <500MB | P0 |
| M2: 編排配置 | Docker Compose 本地、Helm K8s 生產 | 啟動時間 <3分鐘 | P0 |
| M3: 監控與高可用 | Prometheus、HPA、備份策略 | 可用性 >99.5% | P1 |
| M4: CI/CD 自動化 | 自動測試→構建→部署 流程 | 部署時間 <10分鐘 | P1 |

---

## 🔄 工作流程

### Phase 1: 容器化設計
```
1. Dockerfile 編寫
   ├─ 多階段構建 (Multi-stage build)
   │  ├─ stage 1: 編譯器 (Node, Go, Python)
   │  ├─ stage 2: 應用程式運行時
   │  └─ 最終映像: 僅必要的執行檔與依賴
   ├─ 基礎映像選擇
   │  ├─ 前端: node:20-alpine (輕量)
   │  ├─ 後端: golang:1.20-alpine (Go)
   │  └─ 資料工程: python:3.11-slim (Python)
   ├─ 層優化
   │  ├─ 頻繁變更的層放上方? 否，放下方
   │  ├─ 合併相關步驟減少層數
   │  └─ 移除暫存檔案 (npm cache, apt lists)
   └─ 安全最佳實踐
       ├─ 非 root 使用者執行
       ├─ 最小化安裝套件
       └─ SECRETS 不烙印進映像

2. 映像大小優化
   ├─ 前端 (Vite 構建)
   │  ├─ 目標: <100MB
   │  ├─ 優化: gzip 啟用、代碼分割
   │  └─ 驗證: docker images output
   ├─ 後端 (Go 編譯)
   │  ├─ 目標: <80MB
   │  ├─ 優化: upx 壓縮、刪除符號表
   │  └─ 驗證: CGO_ENABLED=0 減少依賴
   └─ 資料工程 (Python)
       ├─ 目標: <300MB
       └─ 優化: requirements.txt 精簡、多階段

3. 網路與環境
   ├─ 環境變數管理
   │  ├─ .env 檔案 (本地開發)
   │  ├─ K8s ConfigMap (組態)
   │  └─ K8s Secret (敏感資料)
   ├─ 埠口暴露 (EXPOSE 指令)
   ├─ 健康檢查 (HEALTHCHECK)
   │  └─ curl http://localhost:8080/health
   └─ 日誌輸出 (stdout/stderr, 不檔案)
```

### Phase 1.5: 🆕 本地快速部署（VS Code F5）

**新增：一鍵智能部署腳本** (`.vscode/scripts/docker-task.ps1`)

優點：
- ✅ 自動檢查 `.env` 是否存在，不存在自動從 template 複製
- ✅ 自動建立 Docker 網路 (`br_dashboard`)
- ✅ 智能判斷是否需初始化：首次自動執行 DB schema 遷移
- ✅ Windows Docker + WSL Docker 自動 fallback
- ✅ 清楚的彩色提示訊息

使用方式：
```bash
# F5 快速啟動
F5 → "F5: Docker Quick Deploy"  # 智能判斷是否需初始化
F5 → "F5: Docker Full Bootstrap" # 強制重新初始化
F5 → "docker:down"               # 停止所有服務
```

Tasks 定義：
- `docker:quick-up` - 快速啟動（首次自動初始化，之後只啟動）
- `docker:bootstrap-full` - 完整重新初始化
- `docker:down` - 停止服務

關鍵改進：
1. **自動 .env 生成** → 從 `docker/.env.template` 複製
2. **首次偵測** → 檢查 `postgres_data` volume 是否存在
3. **智能初始化** → 首次自動跑 `docker-compose-init.yaml`
4. **WSL 支持** → 自動檢測 WSL docker，無需手動配置

### Phase 2: Docker Compose 本地開發
```
4. 服務組態設定
   ├─ 核心服務定義
   │  ├─ backend: Go 應用程式，埠 8080
   │  ├─ frontend: Vite 開發伺服器，埠 5173
   │  ├─ postgresql: 資料庫，埠 5432
   │  ├─ redis: 快取，埠 6379
   │  ├─ qdrant: 向量 DB，埠 6333
   │  └─ airflow: 資料管道，埠 8085
   ├─ 程序跟蹤
   │  └─ 服務依賴順序 (depends_on)
   ├─ 環境變數 (env_file)
   │  └─ .env.local 版本
   └─ 卷管理 (volumes)
       ├─ 資料庫持久化: postgres_data:/var/lib/postgresql/data
       ├─ 程式碼掛載: ./Taipei-City-Dashboard-BE:/app (熱重載)
       └─ Redis 持久化: redis_data:/data

5. 開發工作流
   ├─ 啟用: docker compose up -d
   ├─ 檢查健康: docker compose ps
   ├─ 檢視日誌: docker compose logs -f [service]
   ├─ 進入容器: docker compose exec [service] /bin/bash
   ├─ 資料庫遷移: docker compose exec backend go run main.go migrate
   └─ 清理: docker compose down -v (含卷)

6. 本地端口對應
   ├─ http://localhost:5173 → Frontend (Vite)
   ├─ http://localhost:8080 → Backend API
   ├─ http://localhost:5432 → PostgreSQL (psql client)
   ├─ http://localhost:6379 → Redis (redis-cli)
   └─ http://localhost:6333 → Qdrant

範例 docker-compose.yaml:
[見參考檔案中的 docker/docker-compose.yaml]
```

### Phase 3: Kubernetes 與 Helm Chart
```
7. Helm Chart 結構設計
   ├─ Chart.yaml: 元資料 (名稱、版本、依賴)
   ├─ values.yaml: 預設值 (replicas, resources, image tags)
   ├─ templates/:
   │  ├─ deployment.yaml: Pod 控制器
   │  ├─ service.yaml: 服務暴露
   │  ├─ ingress.yaml: HTTP 路由
   │  ├─ pvc.yaml: 持久化儲存
   │  └─ configmap.yaml: 非敏感組態
   └─ 環境值檔案
       ├─ values-dev.yaml
       ├─ values-sit.yaml (測試)
       └─ values-prod.yaml

8. 部署配置
   ├─ 副本與高可用性 (Replicas)
   │  ├─ prod: 3+ 副本
   │  ├─ staging: 2 副本
   │  └─ dev: 1 副本
   ├─ 資源限制 (resources)
   │  ├─ requests: 容器最少資源
   │  ├─ limits: 容器最多資源
   │  └─ 範例: requests: {cpu: 500m, memory: 512Mi}
   ├─ 健康檢查 (livenessProbe, readinessProbe)
   │  ├─ liveness: 重啟失敗容器
   │  ├─ readiness: 流量路由
   │  └─ 檢查路由: /health 端點
   ├─ 自動擴展 (HPA)
   │  ├─ CPU 觸發 >70% → +1 副本
   │  ├─ 記憶體觸發 >80% → +1 副本
   │  └─ max replicas: 10
   └─ 滾動更新
       ├─ 策略: RollingUpdate
       ├─ MaxSurge: 1 (額外副本)
       └─ MaxUnavailable: 0 (零停機)

9. 資料庫與存儲管理
   ├─ PostgreSQL
   │  ├─ PVC (持久化聲明): postgres-pvc.yaml
   │  ├─ 初始化腳本: initdb.d 卷掛
   │  ├─ 備份策略: daily 自動備份 (CronJob)
   │  └─ 復原測試: 月度演練
   ├─ Redis
   │  ├─ 記憶體限制: maxmemory 設定
   │  ├─ 驅逐策略: allkeys-lru
   │  └─ 持久化: appendonly.aof
   └─ Qdrant
       ├─ 向量索引持久化: /var/lib/qdrant
       ├─ 快照備份: weekly

10. 網路與入口
    ├─ Service (內部)
    │  ├─ ClusterIP: 預設，僅內部通訊
    │  ├─ 命名: backend-service, frontend-service
    │  └─ 埠對應: containerPort 8080 → port 80
    ├─ Ingress (外部)
    │  ├─ 主機: dashboard.taipei.gov.tw
    │  ├─ TLS/HTTPS: ssl-redirect 啟用
    │  ├─ 路徑路由:
    │  │  ├─ / → frontend-service:80
    │  │  └─ /api → backend-service:80
    │  ├─ 速率限制: 100 req/min per IP
    │  └─ CORS 策略: 允許的域名
    └─ NetworkPolicy
        └─ 預設拒絕，除外列表允許
```

### Phase 4: 監控、日誌、CI/CD
```
11. 監控與告警
    ├─ Prometheus
    │  ├─ scrape_interval: 30s
    │  ├─ 指標: kube_pod_cpu_request, kube_pod_memory_request
    │  ├─ 告警規則 (Prometheus rules)
    │  │  ├─ PodCrashLooping: 重啟率 >3/5min
    │  │  ├─ KubernetesPodNotHealthy: ready pods <expected
    │  │  ├─ CPUUsage: >85% for 5min
    │  │  └─ MemoryUsage: >90% for 5min
    │  └─ 保留: 15 天
    ├─ Grafana 儀表板
    │  ├─ 節點資源 (CPU, 記憶體, 磁碟)
    │  ├─ Pod 生命周期
    │  ├─ 應用指標 (RPS, 延迟, 錯誤率)
    │  └─ 資料庫效能 (查詢時間, 連接池)
    └─ 告警推送
        ├─ Slack: 嚴重告警 (#infrastructure)
        ├─ PagerDuty: 隨叫隨到
        └─ 郵件: 信息性告警 (daily digest)

12. 日誌聚合
    ├─ ELK Stack (Elasticsearch, Logstash, Kibana)
    │  ├─ 所有容器日誌轉發 stdout
    │  ├─ Logstash 解析與轉換
    │  ├─ Elasticsearch 索引 (日期模式)
    │  └─ Kibana 審查與搜尋
    ├─ 保留政策
    │  ├─ ERROR: 30 天
    │  ├─ WARN: 7 天
    │  └─ INFO: 3 天
    └─ 搜尋範例
        └─ kubernetes.labels.app:backend AND log_level:ERROR

13. CI/CD 管道
    ├─ 觸發: Git push 至 main/develop/staging 分支
    ├─ 階段 1: 檢查與測試
    │  ├─ Linting (eslint, golangci-lint)
    │  ├─ 單元測試 (95% 涵蓋率)
    │  └─ 容器安全掃描 (Trivy)
    ├─ 階段 2: 構建與推送
    │  ├─ Docker 映像構建
    │  ├─ 映像掃描續 (漏洞檢查)
    │  └─ 推送至 Docker Registry
    ├─ 階段 3: 部署
    │  ├─ 開發 (develop): 自動
    │  ├─ 測試 (staging): 自動
    │  └─ 生產 (main): 手動批准 + 自動回滾
    └─ 生產部署檢查
        ├─ 藍綠部署 (Blue-Green)
        ├─ 金絲雀部署 (Canary): 10% 流量
        └─ 自動回滾: 錯誤率 >3% 觸發

14. 備份與災難恢復
    ├─ 備份策略
    │  ├─ PostgreSQL: 日備份 (13:00 UTC)
    │  ├─ Qdrant: 週備份 (Sunday 02:00)
    │  └─ 組態: Git 版本控制
    ├─ 備份驗證
    │  └─ 月度復原測試 (RTO/RPO 驗證)
    ├─ RTO/RPO 目標
    │  ├─ RTO: <4 小時
    │  ├─ RPO: <1 小時
    │  └─ 關鍵系統: RTO <1 小時
    └─ 災難恢復 runbook
```

---

## 💡 技術決策點

### 容器登錄檔選擇
| 登錄檔 | 適用場景 | 成本 |
|--------|---------|------|
| Docker Hub | 開源專案 | 免費 (公開) |
| ECR (AWS) | AWS 部署 | 按儲存計費 |
| Harbor (自託管) | 隱私專案 | 基礎設施成本 |

### Helm Chart 環境隔離
```bash
# 開發
helm install taipei-dashboard ./helm-chart -f values-dev.yaml -n dev

# 測試
helm install taipei-dashboard ./helm-chart -f values-sit.yaml -n staging

# 生產
helm install taipei-dashboard ./helm-chart -f values-prod.yaml -n prod
```

### 資源要求估算
| 環境 | CPU| 記憶體 | 儲存 |
|------|-----|--------|------|
| Dev | 2 | 4GB | 20GB |
| Staging | 4 | 8GB | 50GB |
| Production | 8+ | 16GB+ | 100GB+ |

### 高可用性設置
```
生產環境架構:
┌─────────────────────────────┐
│ 使用者 (Internet)            │
└────────────┬────────────────┘
             │
    ┌────────▼─────────┐
    │  Nginx (LB)      │  (3x 高可用)
    └────────┬─────────┘
    ┌────────▼────────────────────┐
    │  Kubernetes Cluster       │
    │  ├─ Backend Pods (3x)    │
    │  ├─ Frontend Pods (2x)   │
    │  └─ Ingress Controller   │
    └────────┬───────────────────┘
             │
    ┌────────▼─────────────────┐
    │ PersistentVolumes        │
    │ ├─ PostgreSQL (RDS)      │
    │ ├─ Redis (ElastiCache)   │
    │ └─ Qdrant (NFS)          │
    └──────────────────────────┘
```

---

## 🛡️ 實踐檢查清單

### 容器化
- [ ] Dockerfile 多階段構建已實現
- [ ] 映像大小在目標內 (<500MB)
- [ ] 安全掃描 (Trivy) 0 嚴重漏洞
- [ ] 非 root 使用者運行

### Docker Compose
- [ ] `docker compose up` 一鍵啟動
- [ ] 所有服務健康檢查通過
- [ ] 卷掛載無誤 (資料持久化)
- [ ] 環境變數隔離 (.env 不入 git)

### Kubernetes/Helm
- [ ] Helm chart lint 通過 (`helm lint`)
- [ ] 所有環境值檔已驗證
- [ ] 副本數和資源限制合理
- [ ] 健康檢查端點已實現
- [ ] HPA 規則已測試
- [ ] 入口 TLS 證書已配置

### 監控與日誌
- [ ] Prometheus 指標已公開 (metrics 端點)
- [ ] Grafana 儀表板已設定
- [ ] 告警規則已測試 (模擬失敗)
- [ ] 日誌聚合正常運作
- [ ] 保留政策符合要求

### 備份與災難恢復
- [ ] 備份腳本已測試
- [ ] 復原流程已驗證 (復原時間 <目標)
- [ ] Runbook 已編寫與更新

---

## 📚 參考檔案

- **Docker Compose**: [docker/docker-compose.yaml](../docker/docker-compose.yaml)
- **Helm Chart**: [helm-chart/](../helm-chart/)
- **Dockerfile (後端)**: [Taipei-City-Dashboard-BE/Dockerfile](../Taipei-City-Dashboard-BE/Dockerfile)
- **Dockerfile (前端)**: [Taipei-City-Dashboard-FE/Dockerfile](../Taipei-City-Dashboard-FE/Dockerfile)
- **Dockerfile (資料工程)**: [Taipei-City-Dashboard-DE/docker/](../Taipei-City-Dashboard-DE/docker/)
- **Cloud Build**: [Taipei-City-Dashboard-BE/cloudbuild.yaml](../Taipei-City-Dashboard-BE/cloudbuild.yaml)
