# 🚀 Taipei City Dashboard - 組員快速部署指南

## 目標
按 **F5** 一鍵快速部署全棧應用，無需手動設定。

---

## 📋 前置要求

### 必須安裝
選擇其中之一：
- **Docker Desktop**（Windows/Mac 推薦）
  - 下載：https://www.docker.com/products/docker-desktop
  - 安裝後需重開系統，啟動 Docker Desktop
  
- **或 WSL 2 + Docker**（已安裝者可用）
  ```powershell
  # 在 PowerShell 執行
  wsl.exe -d Ubuntu
  docker --version  # 確認 docker 可用
  ```

### 確認環境
開啟 PowerShell 或 WSL 終端，執行：
```bash
docker --version
docker compose version
```
若都顯示版本號，表示就緒。

---

## ⚡ 一鍵部署

### 首次部署（完整初始化）

1. **VS Code 開啟專案根目錄**
   
2. **按 F5** → 選擇 `F5: Docker Quick Deploy`

3. **等待部署完成**（約 3-5 分鐘首次，之後通常 <1 分鐘）

   預期看到：
   ```
   === Taipei City Dashboard Deployment ===
   INFO: .env not found. Creating from template...
   OK: .env created...
   INFO: First-time setup detected. Running bootstrap...
   OK: Services started. Check status below:
   ```

4. **驗證登入**
   - 開啟瀏覽器：http://localhost:8080
   - 帳號：`admin@admin.com`
   - 密碼：`Admin1234!`

---

## 📊 新增特定組件部署 (以雙北空品組件為例)

當您需要將特定的「空品監測」等帶有地圖與資料庫查詢的組件部署到 Docker 環境時，請按照以下步驟：

### 一鍵部署與同步
在專案根目錄執行以下腳本，它會自動完成：元數據更新、資料庫建表、匯入模擬數據、生成地圖檔案、以及重啟前端。
```bash
bash ./migrations/run_deploy_air_quality.sh
```

### 手動同步地圖資料
若您修改了資料庫中的測站位置或數值，需要手動同步至地圖檔案時：
```bash
# 生成 GeoJSON 並重啟前端識別
bash ./migrations/export_air_quality_geojson.sh
docker restart dashboard-fe
```

---

## 🔧 常見指令

| 操作 | 快捷鍵 | 描述 |
|-----|--------|------|
| 快速啟動 | F5 | 智能判斷是否需初始化，自動部署 |
| 停止服務 | 無 | 執行 F5 → 選 `docker:down` |
| 查看日誌 | 無 | 在 Terminal 執行 `docker logs <container-name>` |
| 重新初始化 | 無 | F5 + 選 `docker:bootstrap-full` |

---

## 📍 服務端口對應

| 服務 | 本地端口 | 功能 |
|-----|---------|------|
| 前端儀表板 | http://localhost:8080 | 主應用 |
| 後端 API | http://localhost:8088/api | 數據接口 |
| pgAdmin | http://localhost:8889 | 資料庫管理 |
| Nginx（反向代理） | http://localhost | 外部訪問 |
| Qdrant（向量 DB） | http://localhost:6333 | AI 功能（備用） |

---

## ❌ 常見問題排查

### Q1: 按 F5 後一直轉圈或無反應？
**A：** Docker 可能未啟動或超時
- 確認 Docker Desktop 已開啟（檢查系統列）
- 如何重新啟動 F5 即可

### Q2: 容器無法啟動（Exited/Restarting）？
**A：** 通常是 `.env` 設定不完整
- 檢查 `docker/.env` 檔案是否存在
- 確認必填欄位（如 DB 密碼）有值
- 刪除 `.env`，重新按 F5 讓系統自動產生

### Q3: 找不到 docker 指令？
**A：** 環境變數尚未載入
- 關閉 VS Code 完全重啟
- 確認 Docker Desktop 已啟動
- 如用 WSL docker，確認 Ubuntu 發行版已安裝

---

## 🛠️ 進階操作

### 手動初始化資料庫與遷移
```bash
docker compose -f docker/docker-compose-db.yaml up -d
docker compose -f docker/docker-compose-init.yaml up
# 若只需跑特定的遷移資料：
# docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-migrations
```

---

## 📞 求助

遇到問題時檢查：
1. `.github/skills/infrastructure-deployment/SKILL.md` — 部署詳細指南
2. `docker/.env` — 環境變數設定是否正確
3. Docker Desktop 版本是否最新

---

**祝部署順利！🎉**
