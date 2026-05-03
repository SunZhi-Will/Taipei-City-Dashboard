# Docker 環境配置參考手冊

日期: 2026-04-14  
目的: 提供完整的環境變數、服務埠位、容器依賴關係參考  
讀者: 開發人員、DevOps 工程師、QA  

---

## 1. 服務埠位地圖

| 服務名稱 | 容器埠位 | 主機埠位 | 用途 | 狀態 |
|---|---|---|---|---|
| Nginx (`nginx`) | 80, 443 | 8080:80 | 反向代理、靜態資源、API 路由 | ✅ 必須 |
| 儀表板前端 (`dashboard-fe`) | 5173 | 內部 | Vue 3 Vite，由 Nginx 代理 | ✅ 必須 |
| 儀表板後端 (`dashboard-be`) | 8080 | 內部 | Go Gin API，由 Nginx 代理 (/api) | ✅ 必須 |
| PostgreSQL 資料庫 (`postgres-data`) | 5432 | 5432 | 儀表板資料庫 | ✅ 必須 |
| PostgreSQL 管理 (`postgres-manager`) | 5432 | 5433 | 管理系統資料庫 | ✅ 必須 |
| pgAdmin 管理工具 (`pgadmin`) | 80 | 8889 | 資料庫圖形介面 | ✅ 可選 |
| Redis 快取 (`redis`) | 6379 | 6379 | 後端 Session & 快取 | ✅ 必須 |
| Qdrant 向量 DB (`qdrant`) | 6333 | 6333 | AI 功能（向量搜尋） | ⏸️ 待命 |
| 向量 DB 升級工具 (`vector-db-upgrade`) | N/A | N/A | 一次性遷移工具 | ⏸️ 待命 |

### 戶端訪問地圖

```
使用者瀏覽器 (Windows)
  ↓
http://localhost:8080  ← 綁到 Nginx 的 80 埠
  ↓
Nginx (容器內 :80)
  ├─ / → 儀表板 FE (dashboard-fe :5173)
  └─ /api → 儀表板 BE (dashboard-be :8080)

http://localhost:8889 ← pgAdmin GUI
  ↓
pgAdmin (容器內 :80)
  ↓
連線池 → PostgreSQL
```

---

## 2. 環境變數完整清單

### A. 資料庫連線

#### PostgreSQL (主資料庫)
```bash
# Docker Compose 環境變數
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres              # 生產環境務必改
POSTGRES_DB=dashboard

# 連線字串 (後端使用)
DASHBOARD_POSTGRES_CONN=postgres://postgres:postgres@postgres-data:5432/dashboard
MANAGER_POSTGRES_CONN=postgres://postgres:postgres@postgres-manager:5432/dashboardmanager

# 連線逾時設定
POSTGRES_CONNECT_TIMEOUT=10
```

#### 使用 pgAdmin 連線
1. 開啟 http://localhost:8889
2. 登入: admin@admin.com / Admin1234!
3. 新增伺服器:
   - Host: `postgres-data` 或 `postgres-manager`
   - Port: `5432`
   - Username: `postgres`
   - Password: `postgres` (見上)

### B. Redis 快取

```bash
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=                 # 目前未設密碼（開發環境）
REDIS_EXPIRY_HOURS=24           # Session 過期時間
REDIS_MAX_POOLSIZE=10
```

### C. API 與認證

```bash
# 後端 API
API_PORT=8080                   # 容器內 Go Gin 埠位
API_ENV=development             # 或 production
API_LOG_LEVEL=info              # 或 debug
API_TIMEOUT_SECONDS=30

# JWT (如適用)
JWT_SECRET=your-secret-key      # ⚠️ 生產環境務必設定
JWT_EXPIRY_HOURS=24

# CORS 設定
ALLOWED_ORIGINS=localhost,localhost:8080,127.0.0.1:8080
```

### D. 儀表板應用

```bash
# FE 構建設定
VUE_ENV=development
VITE_API_BASE_URL=/api          # 相對路徑，由 Nginx 代理
VITE_MAP_TOKEN=your-map-api-key # (若使用地圖 API)

# 應用層
APP_NAME=Taipei-City-Dashboard
APP_TIMEZONE=Asia/Taipei
```

### E. Qdrant 向量 DB (AI 功能，可選)

```bash
QDRANT_URL=http://qdrant:6333
QDRANT_API_KEY=                 # 空值表示無認証（開發環境）
QDRANT_COLLECTION_NAME=dashboard_vectors
QDRANT_EMBEDDING_MODEL=multilingual-e5-large
```

### F. 日誌與監控

```bash
LOG_LEVEL=info                  # 或 debug, warn, error
LOG_FORMAT=json                 # 或 text
LOG_OUTPUT_STDOUT=true          # 傳送到容器 stdout
LOG_FILE=/var/log/dashboard.log # (容器內路徑)
```

---

## 3. Docker Compose 檔案架構

```yaml
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"               # ← 外部訪問點
    depends_on:
      - dashboard-fe
      - dashboard-be
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d  # 代理設定
    networks:
      - br_dashboard

  dashboard-fe:
    build:
      dockerfile: Dockerfile    # 基於 Node.js 構建
    depends_on:
      - dashboard-be
    environment:
      VITE_API_BASE_URL: /api   # ← FE 呼叫後端
    networks:
      - br_dashboard

  dashboard-be:
    build:
      dockerfile: Dockerfile    # 基於 Go 構建
    depends_on:
      - postgres-data
      - redis
    environment:
      DASHBOARD_POSTGRES_CONN: postgres://...  # ← 連 DB
      REDIS_URL: redis://...                   # ← 連快取
    networks:
      - br_dashboard

  postgres-data:
    image: postgres:16-postgis
    volumes:
      - postgres_data:/var/lib/postgresql/data  # 持久化
    environment:
      POSTGRES_PASSWORD: postgres
    networks:
      - br_dashboard

  redis:
    image: redis:7.2.3
    networks:
      - br_dashboard

networks:
  br_dashboard:
    driver: bridge

volumes:
  postgres_data:
```

---

## 4. Nginx 反向代理設定

檔案: `docker/nginx/conf.d/default.conf`

```nginx
upstream frontend {
    server dashboard-fe:5173;
}

upstream backend {
    server dashboard-be:8080;
}

server {
    listen 80;
    server_name localhost 127.0.0.1 citydashboard.taipei;

    # 前端靜態資源與 SPA 路由
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        
        # WebSocket 支援 (Vite HMR)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # API 路由至後端
    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 30s;
    }

    # 靜態資源快取
    location ~* \.(js|css|png|jpg|gif|ico)$ {
        expires 1d;
        add_header Cache-Control "public";
    }
}
```

### 路由邏輯

| 訪問路徑 | 實際目標 | 容器埠位 | 說明 |
|---|---|---|---|
| `http://localhost:8080/` | `dashboard-fe:5173/` | 5173 | FE 索引頁 (Vue) |
| `http://localhost:8080/foo` | `dashboard-fe:5173/foo` | 5173 | SPA 路由 |
| `http://localhost:8080/api/users` | `dashboard-be:8080/users` | 8080 | BE API 端點 |

---

## 5. 容器初始化流程

### 第一次啟動 (bootstrap-full)

```
Step 1: 執行 docker-compose-db.yaml
  └─ 啟動 PostgreSQL 及初始 schema

Step 2: 執行 docker-compose-init.yaml
  └─ 執行初始化腳本 (npm install, go build 等)

Step 3: 執行 docker-compose.yaml
  └─ 啟動完整應用 (8 個容器)

Step 4: 資料卷檢查
  └─ 若 postgres_data 卷存在 → 跳過 DB 初始化
  └─ 若不存在 → 執行初始化
```

### 後續啟動 (quick-up)

```
快速檢查 postgres_data 卷是否存在
  ├─ Yes → 直接 docker-compose up (省時 2-3 分鐘)
  └─ No  → 執行完整初始化
```

---

## 6. 常用環境設定場景

### 場景 1: 開發環境 (預設)

```bash
# docker/.env
LOG_LEVEL=debug
API_ENV=development
VITE_API_BASE_URL=/api
JWT_SECRET=dev-secret-key      # 非必須，但建議設定
POSTGRES_PASSWORD=postgres
```

**特點**: 完整日誌、較寬鬆的驗證、快速重啟

---

### 場景 2: SIT 環境 (整合測試)

```bash
LOG_LEVEL=info
API_ENV=staging
VITE_API_BASE_URL=https://sit-dashboard.example.com/api
JWT_SECRET=sit-secret-key-from-vault
POSTGRES_PASSWORD=sit-db-password-from-vault

# 資料庫
DASHBOARD_POSTGRES_CONN=postgres://sit-user:sit-pass@sit-postgres:5432/dashboard
```

**部署**: 使用 Kubernetes 或 Docker Swarm

---

### 場景 3: 生產環境

```bash
LOG_LEVEL=warn
API_ENV=production
VITE_API_BASE_URL=https://dashboard.taipei.gov.tw/api
JWT_SECRET=$(cat /run/secrets/jwt_secret)  # 使用 Secrets
POSTGRES_PASSWORD=$(cat /run/secrets/db_password)

# 資料庫 (獨立 RDS)
DASHBOARD_POSTGRES_CONN=postgres://prod-user:$(cat /run/secrets/db_password)@prod-postgres.example.com:5432/dashboard

# 快取 (獨立 Redis)
REDIS_URL=redis://prod-redis.example.com:6379

# Qdrant (若用 AI 功能)
QDRANT_URL=https://qdrant.example.com
QDRANT_API_KEY=$(cat /run/secrets/qdrant_key)
```

**部署**: Helm + Kubernetes，所有密鑰來自 Secrets Store

---

## 7. 故障排查矩陣

| 問題 | 常見原因 | 排查指令 | 解決 |
|---|---|---|---|
| Port 8080 無反應 | Nginx 未就緒 | `docker logs nginx` | 檢查 Nginx 配置 |
| 後端 API 超時 | PostgreSQL 連線失敗 | `docker logs dashboard-be` | 檢查 DB 密碼 / 連線字串 |
| FE 無法載入 | npm 依賴缺失 | `docker logs dashboard-fe` | 重建 FE 容器 |
| Redis 連線逾時 | Redis 容器未啟動 | `docker ps \| grep redis` | 重啟 Redis |
| 資料庫無法初始化 | 權限或卷狀態 | `docker volume ls` | 刪除舊卷，重新初始化 |

---

## 8. 安全性檢查清單

- [ ] `.env` 檔案 **絕不** 提交至 Git（已在 `.gitignore`）
- [ ] 生產環境密鑰預存於 Secrets Manager（不可放在 `.env`）
- [ ] PostgreSQL 密碼改為強密碼（超過 12 字元）
- [ ] JWT_SECRET 改為隨機字串（至少 32 字元）
- [ ] Redis 啟用密碼 (如有外網訪問)
- [ ] Nginx 配置禁止目錄列表（已預設）
- [ ] 生產環境僅開放必須埠位 (80, 443)
- [ ] 定期更新容器基礎映像版本

---

## 9. 效能調優參考

### PostgreSQL 連線池

```bash
# 預設值（開發環境）
POSTGRES_MAX_CONNECTIONS=100

# 優化值（中等負載）
POSTGRES_MAX_CONNECTIONS=200
POSTGRES_SHARED_BUFFERS=256MB
```

### Redis 快取策略

```bash
REDIS_MAXMEMORY=256mb
REDIS_MAXMEMORY_POLICY=allkeys-lru    # 淘汰最少使用鍵
```

### Nginx 工作執行緒

```nginx
# 在 Dockerfile 或 nginx.conf
worker_processes auto;
worker_connections 1024;
```

---

## 10. 監控與告警

### 容器健康檢查

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 日誌聚合 (未來計劃)

```bash
# 蒐集所有容器日誌
docker logs -f $(docker ps -q)

# 或使用 ELK Stack / Datadog 等
```

---

## 附錄: 環境變數模板

```bash
# ============================================
# Taipei-City-Dashboard development .env
# Generated: 2026-04-14
# ============================================

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=dashboard

# Application
API_PORT=8080
API_ENV=development
LOG_LEVEL=info
APP_NAME=Taipei-City-Dashboard
APP_TIMEZONE=Asia/Taipei

# Database Connections
DASHBOARD_POSTGRES_CONN=postgres://postgres:postgres@postgres-data:5432/dashboard
MANAGER_POSTGRES_CONN=postgres://postgres:postgres@postgres-manager:5432/dashboardmanager

# Cache
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=
REDIS_EXPIRY_HOURS=24

# API & Authentication
JWT_SECRET=dev-secret-key
JWT_EXPIRY_HOURS=24

# Frontend
VITE_API_BASE_URL=/api
VUE_ENV=development

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=Admin1234!

# Vector DB (optional, for AI features)
QDRANT_URL=http://qdrant:6333
QDRANT_API_KEY=

# Network
ALLOWED_ORIGINS=localhost,localhost:8080,127.0.0.1:8080
```

---

**版本歷史:**
- 2026-04-14: 初版，基於生產部署經驗編寫
