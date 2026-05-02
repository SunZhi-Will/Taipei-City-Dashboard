# 熱更新啟動延遲修正 / Hot Reload Startup Latency Fix

## 2026-04-17 17:36

- objective:
  - 降低前端開發時「看似每次刷新都要重跑 Vite」造成的等待時間。
  - 修正 Docker 開發路徑中容易導致 HMR 不穩定與流程過重的設定。

- files:
  - Taipei-City-Dashboard-FE/vite.config.js
  - .vscode/scripts/docker-task.ps1

- summary:
  - 移除 Docker 模式下 Vite `hmr.host` 與 `hmr.clientPort` 的硬編碼，避免在 80/8080 雙入口情境產生 websocket 錯配，降低全頁重整與熱更新失敗機率。
  - 將 `quick-up` 流程改為預設不執行 `--build`，避免每次開發啟動都觸發不必要的重建，縮短可互動時間。

- change-type:
  - Fixed

- technical-details:
  - `Taipei-City-Dashboard-FE/vite.config.js`
  - 移除 Docker server 設定中的 `hmr` 區塊（`protocol/host/clientPort`），改由 Vite 在實際入口推導 websocket 端點。
  - `.vscode/scripts/docker-task.ps1`
  - Windows Docker quick-up: `docker compose -f docker-compose.yaml up -d --build` -> `docker compose -f docker-compose.yaml up -d`。
  - WSL Docker quick-up: `docker compose ... up -d --build dashboard-be && docker compose ... up -d` -> 單次 `docker compose ... up -d`。

- verification:
  - `get_errors` 檢查以下檔案皆無錯誤：
  - `Taipei-City-Dashboard-FE/vite.config.js`
  - `.vscode/scripts/docker-task.ps1`
  - 以全文檢查確認 quick-up 中已無 `--build`（僅 `bootstrap-full` 保留建置行為）。

- performance-impact:
  - 預期減少 quick-up 路徑的建置與重建開銷，縮短前端進入可用狀態的時間。
  - 預期降低由 HMR 端點錯配引發的全頁 reload 次數。

- impact-risk:
  - 若開發者在 quick-up 前更新了 Dockerfile 或基底映像，quick-up 不會自動重建，需手動執行 `docker:bootstrap-full`。
  - 移除 HMR 硬編碼後，若特殊網路/反向代理環境依賴固定 clientPort，需額外環境化設定（目前未啟用）。

- regression-test:
  - 執行 `docker:quick-up` 後確認 `dashboard-fe` 不再觸發不必要重建。
  - 修改任一 Vue SFC（如 SideBar.vue）確認出現 `[vite] hmr update` 且無整體 Vite 重新啟動。
  - 從 `http://localhost:8080` 與 `http://localhost` 各驗證一次前端更新行為。

- traceability:
  - N/A

- next-actions:
  - 建議新增 `docker:quick-up-build-backend` 任務，作為需要更新後端映像時的中間選項（優先級: Medium）。
