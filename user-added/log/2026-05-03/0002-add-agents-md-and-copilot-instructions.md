# 新增 AGENTS.md 與 copilot-instructions.md / Add AGENTS.md and copilot-instructions.md

## 2026-05-03 00:02

- objective:
  - 建立 AI Agent 專用部署指南 AGENTS.md，供 Claude Code、GitHub Copilot、Cursor 等 AI 工具直接讀取並執行部署流程
  - 更新 `.github/copilot-instructions.md`，確保 Copilot 能讀取最新行為準則並引用 AGENTS.md

- files:
  - AGENTS.md
  - .github/copilot-instructions.md

- summary:
  - 在專案根目錄新增 `AGENTS.md`，內容涵蓋：前置確認、Docker 網路建立、.env 準備、啟動順序（DB → Init → BE/FE → Airflow）、食安 8 組件驗證、AI 功能依賴確認、錯誤對照表、完整重啟流程，以及 AI Agent 補充規則
  - 新增 `.github/copilot-instructions.md`，定義 Copilot 行為準則：繁體中文回應、相對路徑原則、食安組件數量 = 8、部署執行順序、危險操作清單，並引用 AGENTS.md 各章節

- change-type:
  - Added

- technical-details:
  - AGENTS.md 採「可直接照抄執行」原則，不含概念說明，僅有可執行指令
  - copilot-instructions.md 覆蓋 `.github/copilot-instructions.md` 路徑，Copilot 會自動讀取
  - 衝突優先級：copilot-instructions.md（部署 runbook）> SKILL.md（技術原則）> instructions（流程規範）

- verification:
  - 確認檔案已建立：`ls -la AGENTS.md .github/copilot-instructions.md`
  - 確認內容完整：`wc -l AGENTS.md .github/copilot-instructions.md`

- impact-risk:
  - 純新增文件，不影響任何現有程式碼或服務運行
  - 低風險：僅供 AI Agent 讀取，無執行副作用

- traceability:
  - N/A

- next-actions:
  - 驗證 Copilot 是否正確讀取 copilot-instructions.md（在下一次對話測試部署相關問題）
  - 若 AGENTS.md §5.1 DAG 清單有異動，同步更新本檔與 copilot-instructions.md
