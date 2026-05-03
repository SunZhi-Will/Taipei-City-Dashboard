# Go Build Cache 權限修正 / Go Build Cache Permission Fix

## 2026-04-17 11:12

- objective:
  - 修正 `dashboard-be` 容器啟動時 `air` 因 `/tmp/go-build-cache` 權限不足導致 build 失敗的問題

- files:
  - docker/docker-compose.yaml

- summary:
  - 容器的 `GOCACHE` 環境變數指向 `/tmp/go-build-cache`，但該目錄在前次啟動時由 root 建立後，後續重啟時 `air` 執行身份可能無寫入權限，導致 `permission denied`
  - 將 `command` 從直接執行 `air` 改為先執行 `mkdir -p + chmod -R 777` 再啟動 `air`，確保每次容器啟動都重置快取目錄權限
  - 同時一併處理 `GOMODCACHE`（`/tmp/go/pkg/mod`）目錄，防止相同問題

- change-type:
  - Fixed

- technical-details:
  - 錯誤訊息：`open /tmp/go-build-cache/37/37ced6...d: permission denied`
  - `GOCACHE=/tmp/go-build-cache`、`GOPATH=/tmp/go`、`GOMODCACHE=/tmp/go/pkg/mod` 皆為環境變數設定
  - 修正前 command：`["air", "-c", ".air.toml"]`
  - 修正後 command：`["sh", "-c", "mkdir -p /tmp/go-build-cache /tmp/go/pkg/mod && chmod -R 777 /tmp/go-build-cache /tmp/go && air -c .air.toml"]`
  - 不需重建 image，重啟容器即生效

- verification:
  - 重啟容器後確認 `air` 成功執行 `go build`，不再出現 `permission denied`
  - 指令：`docker compose -f docker/docker-compose.yaml restart dashboard-be`，然後 `docker logs dashboard-be` 確認無錯誤

- impact-risk:
  - 影響範圍：僅 `dashboard-be` 開發容器啟動流程
  - 風險：`chmod 777` 在生產環境不建議，但此為開發用 dev image，無安全疑慮
  - 無需停機，重啟容器即可

- regression-test:
  - 確認 `air` 能正常 watch 並在檔案修改後觸發 `go build`
  - 確認 BE API 可正常回應（`curl http://localhost:8088/api/v1/health` 或相等端點）

- traceability:
  - N/A

- next-actions:
  - 若未來需要持久化 Go module cache 以加速重建，可考慮改用 named volume（`go-build-cache:/tmp/go-build-cache`）取代 chmod 方案
