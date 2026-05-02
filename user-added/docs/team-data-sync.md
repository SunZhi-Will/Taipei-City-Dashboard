# 團隊一鍵資料同步指南 / Team One-Click Data Sync

## 目的

讓每位組員在拉到最新程式碼後，用一個指令把資料狀態同步成與主線一致：

- 食安資料與 metadata 清理重建
- 台北/雙北分流設定同步
- Qdrant 向量資料庫重建
- 基本 API 驗證

## 使用方式

### 方式 A（推薦）：VS Code Task

1. 開啟命令面板，執行 Run Task
2. 選擇 sync:team-data

### 方式 B：Terminal 指令

在專案根目錄執行：

```bash
bash .vscode/scripts/team-sync.sh
```

## 前置條件

- 已安裝 Docker Desktop 並可正常執行 docker 指令
- 專案根目錄已存在 docker/.env（若無，先執行 quick-up 會自動建立）
- 需可連到本機後端 API: http://localhost:8088

## 執行內容

腳本會依序執行：

1. 檢查必要工具（docker/curl/jq）
2. 容器未啟動時，自動執行 quick-up
3. 執行 migrations/reset_food_safety_clean.sh 做 deterministic 重建
4. 套用 migrations/food_safety_components.sql
5. 重啟 dashboard-be
6. 呼叫 POST /api/v1/qdrant/rebuild
7. 驗證台北/雙北儀表板與向量檢索結果

## 注意事項

- 本流程會重建食安資料，不建議在需要保留本機客製食安資料時直接執行
- 若要比對是否成功，請觀察腳本最後的 OK: team data sync completed
