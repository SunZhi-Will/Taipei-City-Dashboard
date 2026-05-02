# WSL Docker Go 快取權限與 Air 路徑修正 / WSL Docker Go Cache Permission and Air Path Fix

## 2026-04-17 15:52

- objective:
  - 修正 `dashboard-be` 在 WSL Docker 下由 `air` 觸發編譯時發生的 `open /tmp/go-build-cache/...: permission denied`。
  - 確保非 root 執行者在開發容器中有穩定可寫的 Go 快取路徑，避免重啟後再次失敗。

- files:
  - Taipei-City-Dashboard-BE/Dockerfile
  - docker/docker-compose.yaml

- summary:
  - 將 Go 相關快取路徑從 `/tmp/*` 改為 `appuser` home 目錄，避免舊權限污染。
  - 在 Dockerfile 的 `prod` 與 `dev` 階段都建立 `appuser` home 與 cache/module 目錄，並做 `chown`。
  - 修正 `air` 安裝位置，改為固定安裝到 `/usr/local/bin`，避免 `GOPATH` 切換後找不到執行檔。
  - 更新 compose 內 `dashboard-be` 環境變數（`HOME`、`GOPATH`、`GOMODCACHE`、`GOCACHE`）對應新路徑。

- change-type:
  - Fixed

- technical-details:
  - Root cause:
    - 既有設定使用 `GOCACHE=/tmp/go-build-cache`，在容器重啟與不同使用者上下文下可能遇到目錄權限殘留，造成 `air` build 失敗。
  - Dockerfile 調整:
    - `useradd -m -r -u 10001 appuser`（建立 home）。
    - 建立並授權：`/home/appuser/.cache/go-build`、`/home/appuser/go/pkg/mod`。
    - 設定環境變數：
      - `HOME=/home/appuser`
      - `GOPATH=/home/appuser/go`
      - `GOMODCACHE=/home/appuser/go/pkg/mod`
      - `GOCACHE=/home/appuser/.cache/go-build`
    - `air` 改為 `GOBIN=/usr/local/bin go install github.com/air-verse/air@v1.61.7`。
  - Compose 調整:
    - `dashboard-be` service 對應更新上述 Go 路徑環境變數。

- verification:
  - 檢查 compose 設定可解析：
    - `wsl -d Ubuntu -- bash -lc "cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker; docker compose config"`。
  - 重建並重啟後端容器：
    - `wsl -d Ubuntu -- bash -lc "cd /mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/docker; docker compose up -d --build dashboard-be"`。
  - 啟動日誌確認：
    - `docker logs dashboard-be --tail 120 --timestamps` 顯示 `air` 啟動、watcher 建立與 `building...`，且不再出現 `permission denied`。
  - 容器狀態確認：
    - `docker ps --filter name=dashboard-be` 顯示 `Up`。

- performance-impact:
  - 正向微幅影響：避免因 cache 權限錯誤導致重複失敗重試與人工重啟成本。
  - 無新增重型運算或額外服務依賴。

- impact-risk:
  - 影響範圍：僅 `dashboard-be` 開發容器的執行環境與快取路徑。
  - 低風險：不涉及 API 契約或資料庫 schema 變更。
  - 注意事項：本次修正仰賴重建容器（`--build`）套用 Dockerfile 變更。

- regression-test:
  - 修改任一 BE `.go` 檔，確認 `air` 能觸發重編譯且不中斷。
  - 呼叫既有後端健康/主要 API（例如 chat endpoint）確認服務可用。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1112-go-build-cache-permission-fix.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 若要加速重建，可評估將 Go module/cache 掛為 named volume。
  - P1: 可移除 compose `version` 欄位，避免 Docker Compose obsolete warning。