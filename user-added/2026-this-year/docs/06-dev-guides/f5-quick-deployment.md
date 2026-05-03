# F5 快速部署指南

日期: 2026-04-14  
目的: 讓團隊成員一鍵啟動 Docker 開發環境  
前提條件: Windows 10/11 + WSL 2 (Ubuntu) + Docker within WSL  
所有者: GitHub Copilot + Sun  

---

## 1. 快速開始 (30 秒)

### 前置檢查
```powershell
# 1. 在 VS Code 中開啟 Taipei-City-Dashboard 資料夾
# 2. 確認已裝 WSL 2 + Ubuntu
wsl.exe -d Ubuntu --version

# 3. 確認 WSL 中有 Docker
wsl.exe -d Ubuntu sh -lc "docker --version"
```

### 一鍵啟動
```
按下 F5 或 Ctrl+F5
```

✅ **當看到這行訊息就代表成功：**
```
[INFO] Docker containers starting... all services initialized
```

### 訪問服務
- **儀表板**: http://localhost:8080（登入帳號：admin@admin.com / Admin1234!）
- **後端 API**: http://localhost:8088/api
- **pgAdmin 資料庫管理**: http://localhost:8889（admin@admin.com / Admin1234!）
- **Qdrant 向量 DB**: http://localhost:6333

### 登入模式切換（不改程式）
- 若登入視窗只看到「台北通登入」，可按住 `Shift`，再點擊 TUIC Logo 一次。
- 會切換到 Email 登入表單；再次操作可切回台北通登入。

---

## 2. 運作原理

### F5 執行流程
```
F5 按鍵
  ↓
.vscode/launch.json 觸發
  ↓
.vscode/tasks.json 啟動任務
  ↓
.vscode/scripts/docker-task.ps1 (PowerShell 指令稿)
  ├─ 檢查 .env 檔是否存在 → 不存在則從模板生成
  ├─ 檢查 Docker 可用性 → 優先用 Windows Docker，fallback 到 WSL
  ├─ 啟動核心容器 (Nginx, PostgreSQL, Redis, 儀表板 FE/BE)
  ├─ 檢查是否首次初始化 → 是則執行 DB 初始化
  └─ 顯示就緒狀態
```

### 支援平台
| 平台 | 狀態 | 說明 |
|---|---|---|
| Windows + WSL 2 (Ubuntu) | ✅ 已驗證 | 主流開發環境 |
| Windows + Docker Desktop | ✅ 支援 | 自動 fallback |
| Mac (Intel) | ⚠️ 需調整 | 路徑分隔符 needs testing |
| Mac (Apple Silicon) | ⚠️ 架構相容性 | 需驗證 |

---

## 3. 關鍵檔案

| 檔案 | 用途 | 責任人 |
|---|---|---|
| `.vscode/launch.json` | F5 觸發點 | IDE 配置 |
| `.vscode/tasks.json` | 任務定義 | IDE 配置 |
| `.vscode/scripts/docker-task.ps1` | **核心邏輯** (161 行) | PowerShell 指令 |
| `docker/.env` | 容器環境變數 | 自動生成（首次執行） |
| `docker/docker-compose.yaml` | 服務定義 | Docker Compose |
| `docker/nginx/conf.d/default.conf` | 反向代理配置 | Nginx 設定 |

---

## 4. 環境變數參考

### `docker/.env` 範本 (自動生成)

```bash
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=dashboard

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=Admin1234!

# Redis
REDIS_PASSWORD=

# 儀表板 BE
MANAGER_POSTGRES_CONN=postgres://postgres:postgres@postgres-manager:5432/dashboardmanager
DASHBOARD_POSTGRES_CONN=postgres://postgres:postgres@postgres-data:5432/dashboard
REDIS_URL=redis://redis:6379

# Qdrant (向量 DB，AI 功能)
QDRANT_URL=http://qdrant:6333
QDRANT_API_KEY=

# 其他
TIMEZONE=Asia/Taipei
LOG_LEVEL=info
```

### 修改環境
若需修改密碼或其他設定，直接編輯 `docker/.env`：
```bash
# 例: 改 PostgreSQL 密碼
POSTGRES_PASSWORD=your-new-password

# 然後重啟
F5 或執行
```

> ⚠️ **首次啟動後修改 .env，需手動重啟容器：**
> ```powershell
> docker-compose down
> F5
> ```

---

## 5. 常見問題 & 故障排除

### Q1: F5 沒反應
**癥狀**: 按 F5 但沒看到 Docker 輸出

**排查**:
1. 確認 VS Code 終端已開啟（Ctrl + `）
2. 檢查 VS Code 設定 → Tasks 是否被禁用
3. 確認 `.vscode/launch.json` 存在
4. 檢查 PowerShell 執行政策：
   ```powershell
   Get-ExecutionPolicy  # 應為 Bypass 或 RemoteSigned
   ```

**解決**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Q2: Docker 找不到 (Docker CLI not found)
**癥狀**: 
```
Docker CLI not found...
```

**原因**: 
- Windows PATH 中沒有 docker.exe
- WSL Ubuntu 中沒有 docker

**排查**:
```powershell
# 1. Windows 路徑檢查
Get-Command docker  # 應該有結果

# 2. WSL 路徑檢查
wsl.exe -d Ubuntu sh -lc "command -v docker"  # 應輸出 /usr/bin/docker
```

**解決**:
- **若 Windows 無 Docker**: 腳本會自動 fallback 到 WSL ✅
- **若 WSL 無 Docker**: 
  ```bash
  # 在 Ubuntu 終端執行
  sudo apt update && sudo apt install -y docker.io
  sudo usermod -aG docker $USER
  ```
  然後重開 WSL 終端

---

### Q3: Port 8080 無反應 / ERR_EMPTY_RESPONSE
**癥狀**: 
```
http://localhost:8080 → ERR_EMPTY_RESPONSE
```

**原因**:
- Nginx 容器未就緒
- 儀表板 FE 容器啟動失敗
- Nginx 設定問題

**排查**:
```powershell
# 1. 檢查容器狀態
wsl.exe -d Ubuntu sh -lc "docker ps"

# 2. 檢查 Nginx 日誌
wsl.exe -d Ubuntu sh -lc "docker logs nginx"

# 3. 檢查 FE 日誌
wsl.exe -d Ubuntu sh -lc "docker logs dashboard-fe"

# 4. 進入 Nginx 測試
wsl.exe -d Ubuntu sh -lc "docker exec nginx curl -s http://localhost:80/ | head -10"
```

**解決**:
```powershell
# 完整重啟
wsl.exe -d Ubuntu sh -lc "cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker && docker-compose down && docker-compose up -d"

# 或使用 PowerShell 腳本
.\.vscode\scripts\docker-task.ps1 -Action quick-up
```

---

### Q4: PostgreSQL 容器反覆重啟
**癥狀**:
```
postgres-data: restarting...
```

**原因**:
- `.env` 缺少 POSTGRES_PASSWORD
- 資料卷權限問題
- 硬碟空間不足

**排查**:
```powershell
# 檢查 .env 是否完整
Get-Content docker/.env | Select-String "POSTGRES"

# 檢查容器日誌
wsl.exe -d Ubuntu sh -lc "docker logs postgres-data | tail -20"
```

**解決**:
```powershell
# 方案 1: 重建 .env（會清除所有數據）
Remove-Item docker/.env
# 然後按 F5

# 方案 2: 刪除資料卷重新初始化
wsl.exe -d Ubuntu sh -lc "docker volume rm postgres_data"
# 然後按 F5
```

---

### Q5: npm 依賴錯誤 (儀表板 FE 啟動失敗)
**癥狀**:
```
dashboard-fe: npm ERR!
或
Vite build failed
```

**原因**:
- `node_modules` 快取問題
- npm 版本不相容

**排查**:
```bash
# 進入 FE 容器
wsl.exe -d Ubuntu sh -lc "docker exec -it dashboard-fe bash"
npm list vite
```

**解決**:
```powershell
# 清除並重建
wsl.exe -d Ubuntu sh -lc "docker rm -f dashboard-fe; cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker && docker-compose up -d dashboard-fe"
```

---

### Q6: Redis 連線逾時
**癥狀**:
```
Backend 日誌: redis connection timeout
```

**排查**:
```bash
# 檢查 Redis 健康狀態
wsl.exe -d Ubuntu sh -lc "docker exec redis redis-cli ping"  # 應回傳 PONG
```

**解決**:
```bash
# 重啟 Redis
wsl.exe -d Ubuntu sh -lc "docker restart redis"
```

---

### Q7: 只有台北通登入，看不到 Email 登入？
**A：** 這是目前預設行為，可用隱藏切換啟用 Email 登入
- 在登入視窗按住 `Shift`，點擊 TUIC Logo 一次。
- 切換成功後可用帳密登入：`admin@admin.com` / `Admin1234!`。

---

## 6. 進階指令

### 檢查完整服務狀態
```powershell
wsl.exe -d Ubuntu sh -lc "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### 查看特定容器日誌
```powershell
wsl.exe -d Ubuntu sh -lc "docker logs <container-name> -f"

# 例:
wsl.exe -d Ubuntu sh -lc "docker logs dashboard-be -f"
```

### 進入容器除錯
```powershell
wsl.exe -d Ubuntu sh -lc "docker exec -it <container-name> bash"

# 例:
wsl.exe -d Ubuntu sh -lc "docker exec -it postgres-data psql -U postgres -d dashboard"
```

### 清除所有容器 & 重新初始化
```powershell
wsl.exe -d Ubuntu sh -lc "cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker && docker-compose down -v"
.\.vscode\scripts\docker-task.ps1 -Action bootstrap-full
```

---

## 7. 驗收清單

使用本指南後，應確認：

- [ ] F5 可成功啟動所有容器
- [ ] Nginx 監聽 localhost:80 與 localhost:8080
- [ ] 儀表板 FE 於 http://localhost:8080 可訪問
- [ ] 後端 API 於 http://localhost:8088/api 可訪問
- [ ] PostgreSQL 可連線，admin 帳戶可登入 pgAdmin
- [ ] 重啟後（Ctrl+C 中止後再 F5），容器能正確恢復
- [ ] `.env` 自動生成於 `docker/.env`
- [ ] 無 Docker 權限錯誤（如非 root 執行）

---

## 8. 下一步

**開發工作流：**
1. 按 F5 啟動基礎環境
2. 在 `Taipei-City-Dashboard-FE` / `Taipei-City-Dashboard-BE` 開發
3. 容器會自動 mount 本地程式碼，熱更新（HMR）設定已啟用
4. 修改後重新整理瀏覽器或重啟服務

**貢獻流程：**
1. 功能完成後，確認所有容器日誌無誤
2. 提交 Git commit
3. 執行 `.vscode/scripts/docker-task.ps1 -Action docker:down` 清理環境
4. 推送至 Git remote

**獲取幫助：**
- 查看這份文件的 [常見問題](#5-常見問題--故障排除) 章節
- 檢查 [docker-environment-reference.md](./docker-environment-reference.md)
- 聯絡專案維護者

---

## 附錄: 完整 PowerShell 指令參考

```powershell
# 啟動所有服務 (包括初始化)
.\.vscode\scripts\docker-task.ps1 -Action bootstrap-full

# 快速啟動 (假設已初始化)
.\.vscode\scripts\docker-task.ps1 -Action quick-up

# 停止所有服務
.\.vscode\scripts\docker-task.ps1 -Action docker:down

# 查看 .env 生成狀態
Get-Content docker/.env

# 查看 docker-compose 設定是否正確
wsl.exe -d Ubuntu sh -lc "cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker && docker-compose config | head -50"
```

---

**版本歷史:**
- 2026-04-14: 初版，基於 WSL 2 + PowerShell 5.1 環境驗證
