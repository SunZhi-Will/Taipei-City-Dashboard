# 修正 F5 持續顯示日誌 / Fix F5 Persistent Log View

## 2026-04-21 10:44

- objective:
  - 讓 VS Code F5 啟動後不要立刻退出，而是持續顯示容器日誌。
  - 讓使用者可在同一個終端以 Ctrl+C 中斷並停止服務。
- files:
  - .vscode/scripts/docker-task.sh
  - .vscode/launch.json
- summary:
  - 為 bash 啟動腳本新增 `--follow` 與 `--stop-on-interrupt` 參數。
  - F5 啟動改為在服務啟動完成後接續執行 `docker compose logs -f`。
  - 在 follow 模式下攔截 Ctrl+C，改為執行 compose down 關閉服務。
- change-type:
  - Fixed
- technical-details:
  - `quick-up` 與 `bootstrap-full` 在 WSL Docker 路徑下完成 compose up 後，若帶有 `--follow` 會切到 `docker compose -f docker-compose-db.yaml -f docker-compose.yaml logs -f --tail=100`。
  - 若同時帶有 `--stop-on-interrupt`，bash trap 會在 INT 訊號時執行 `docker compose down` 與 `docker compose -f docker-compose-db.yaml down`。
  - launch configuration 改為直接帶入 follow/interrupt 參數，確保 F5 預設就是互動式模式。
- verification:
  - 已執行 `bash .vscode/scripts/docker-task.sh quick-up`，確認服務可正常啟動。
  - 已執行 `bash .vscode/scripts/docker-task.sh quick-up --follow --stop-on-interrupt`，確認命令會進入持續輸出模式而非立即結束。
  - 因代理工具無法直接模擬實體鍵盤 Ctrl+C，INT trap 的最終驗證需由 VS Code 終端實際按鍵確認。
- performance-impact:
  - follow 模式僅在 F5 互動啟動時持續串流日誌，不影響容器執行效能。
- impact-risk:
  - 中低風險，影響範圍限於本地開發終端流程。
  - `docker compose logs -f` 會持續佔用一個 F5 終端，屬預期行為。
- regression-test:
  - 按 F5 啟動 `F5: Docker Quick Deploy`，確認終端持續顯示 logs。
  - 在同一終端按 Ctrl+C，確認服務被停止。
  - 執行 `bash .vscode/scripts/docker-task.sh status`，確認停止後容器狀態改變。
- traceability:
  - user-added/log/2026-04-21/1035-f5-launch-fix.md
- next-actions:
  - 可進一步新增 `F5: Logs Only` 設定，讓使用者在不重啟服務的情況下單獨追 log。