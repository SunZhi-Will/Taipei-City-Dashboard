# 修正 F5 啟動設定 / Fix F5 Launch Configuration

## 2026-04-21 10:35

- objective:
  - 修正 VS Code F5 無法執行的問題。
  - 移除無效的 launch type 與錯誤的背景 task 行為，讓使用者可直接在整合終端執行 bash 啟動腳本。
- files:
  - .vscode/launch.json
  - .vscode/tasks.json
- summary:
  - 將 launch.json 中無效的 `type: shell` 改為 VS Code 可執行的 `type: node-terminal`。
  - F5 改為直接執行 bash 腳本，不再依賴 preLaunchTask 串接一次性 shell task。
  - 將 tasks.json 的 quick-up / bootstrap-full 取消 `isBackground`，避免 VS Code 把腳本誤判為背景任務，只顯示「工作將被重新啟用」。
- change-type:
  - Fixed
- technical-details:
  - `type: shell` 不是標準 launch configuration type，因此 F5 會直接失敗。
  - `node-terminal` 會在整合終端執行命令，較符合 bash 啟動腳本與 Ctrl+C 中斷的使用情境。
  - 一次性 docker 啟動腳本不應宣告為 background task，否則 VS Code 會等待背景任務訊號，造成使用者誤以為 F5 失敗。
- verification:
  - 已確認 `.vscode/scripts/docker-task.sh status` 可成功執行並輸出容器狀態。
  - 已確認 `wsl.exe -d Ubuntu bash -c "docker --version"` 可成功執行，代表 WSL Docker 可用。
  - 待使用者於 VS Code 按 F5 驗證 `node-terminal` 啟動行為。
- performance-impact:
  - 無顯著效能影響。
  - 僅調整 VS Code 啟動流程與終端互動方式。
- impact-risk:
  - 低風險，影響範圍限於本地 VS Code 啟動流程。
  - 若系統 PATH 中不存在 `bash`，F5 仍會失敗，但這與既有 task 行為一致。
- regression-test:
  - 在 VS Code 按 F5 執行 `F5: Docker Quick Deploy`。
  - 在終端確認可看到腳本輸出與 docker compose 狀態。
  - 在終端確認可用 Ctrl+C 中斷前景命令。
- traceability:
  - N/A
- next-actions:
  - 若仍需在 F5 後自動追蹤 compose logs，可在腳本內增加 `logs -f` 模式並另設一個 launch configuration。
