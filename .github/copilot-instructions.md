# GitHub Copilot Instructions — Taipei City Dashboard

> Copilot 自動讀取本檔。部署/啟動 Docker 完整步驟見根目錄 [AGENTS.md](../AGENTS.md)。

## 行為準則

1. **語言**：所有回應、commit、文件一律繁體中文。
2. **路徑無關**：所有 Docker 指令使用相對路徑（`cd` 到專案根目錄即可），不要產生包含使用者本機絕對路徑的指令。
3. **食安組件數量 = 8**：詳細列表見 [AGENTS.md §5](../AGENTS.md#5-食安-8-組件驗證核心交付物)。
4. **AI 依賴**：TWCC API Key（外部）、Qdrant（向量 DB）、ONNX e5 Embedding（內建 BE image）。

## 部署任務的執行順序

當使用者要「啟 docker / 部署 / 預覽」時，**嚴格依此順序**：

1. 前置確認（`docker --version`、目錄結構） — [AGENTS.md §0](../AGENTS.md#0-前置確認一次性每台機器)
2. 建外部網路 `br_dashboard` — [AGENTS.md §1](../AGENTS.md#1-建立外部-docker-網路一次性)
3. 準備 `.env`（從 `docker/.env.template` 複製） — [AGENTS.md §2](../AGENTS.md#2-準備-env)
4. 啟 DB → 初始化 → 啟 BE/FE → 啟 Airflow — [AGENTS.md §3](../AGENTS.md#3-啟動順序嚴格依此順序)
5. 驗證容器與 8 食安 DAG — [AGENTS.md §4](../AGENTS.md#4-驗證部署) / [§5](../AGENTS.md#5-食安-8-組件驗證核心交付物)

## 危險操作（**必須先詢問使用者**）

- `docker compose down -v`、`docker volume rm`、`docker system prune`
- 修改 `.env` 內 secret 欄位
- `git push --force`、`git reset --hard`

## 既有規則整合

- 既有 Skill：`.github/skills/infrastructure-deployment/SKILL.md`（基礎設施）
- 既有 Instructions：`.github/instructions/*.instructions.md`（Skill/changelog 政策）
- 三者衝突時：本檔（部署 runbook）> Skill（技術原則）> Instructions（流程規範）

## 提示模板

當使用者只說「跑起來」「啟動 docker」時，Copilot 應主動：

1. 確認目前目錄是否為專案根（執行 `pwd && ls`）
2. 詢問是否首次部署（決定是否跑 `docker-compose-init.yaml`）
3. 詢問是否有 `.env`（沒有就提醒從 template 複製並填關鍵欄位）
4. 才開始執行 [AGENTS.md §3](../AGENTS.md#3-啟動順序嚴格依此順序) 的指令
