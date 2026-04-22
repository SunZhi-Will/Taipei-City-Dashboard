# 新增 AI 金鑰設定 / Add AI Key Configuration

## 2026-04-17 15:21

- objective:
  - 新增並啟用使用者提供的 AI Key，讓後端 TWCC AI 服務可透過環境變數讀取。

- files:
  - docker/.env
- summary:
  - 將 TWCC AI 服務環境變數 `TWCC_API_KEY` 由預設 placeholder 更新為指定金鑰值。
  - 不調整 API URL、模型、timeout 與重試策略，避免影響既有執行行為。
- change-type:
  - Changed
- technical-details:
  - 依後端設定 `global.TWCC.ApiKey <- TWCC_API_KEY` 的讀取鏈路，僅需更新 `docker/.env` 即可讓容器啟動時注入新金鑰。
  - 保持 key 名稱不變，避免破壞 `docker/docker-compose.yaml` 的環境變數映射。
- verification:
  - 檔案檢查：確認 `docker/.env` 中存在 `TWCC_API_KEY=f7896822-6a1a-48fa-bbf7-212ab8d5e60e`。
  - 設定鏈路檢查：後端 `global/global.go` 使用 `getEnv("TWCC_API_KEY", ...)` 讀取該值；`app/services/ai/ai_service.go` 以 `global.TWCC.ApiKey` 初始化 TWCC client。
- performance-impact:
  - 本次僅更新機敏設定值，無程式碼路徑或演算法變更，預期效能影響為無。
- impact-risk:
  - 風險：若服務未重啟，執行中容器仍可能使用舊環境變數。
  - 降級策略：可回復 `docker/.env` 的 `TWCC_API_KEY` 至先前值並重啟服務。
- regression-test:
  - 建議重啟 `dashboard-be` 容器後，呼叫 AI chat endpoint 驗證 200 回應與模型回覆正常。
  - 建議檢查後端容器 log 是否無 `TWCC API returned error status` 金鑰授權錯誤。
- traceability:
  - N/A
- next-actions:
  - 重新啟動後端容器使新環境變數生效（若尚未重啟）。
