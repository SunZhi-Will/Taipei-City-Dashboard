# 變更紀錄：ChatLog 持久化 Answer Mode 與 Tool Metadata / Change Log: Persist Answer Mode and Tool Metadata in ChatLog

## 2026-04-17 11:01

- objective / 目標:
  - 將 AI 回答模式與工具使用資訊持久化到 `chat_logs`，支援後續 KPI（RAG hit rate、tool call ratio）分析。
  - 讓 chatlog 不只保留文字問答，也可追溯回答來源與路徑。

- files / 修改檔案:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go
  - Taipei-City-Dashboard-BE/app/controllers/chatlog.go
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - user-added/log/2026-04-17/1101-chatlog-answer-mode-and-tools-persistence.md

- summary / 變更摘要:
  - BE Model:
    - `ChatLog` 新增 `answer_mode`（varchar）與 `used_tools`（text/JSON string）欄位。
    - `CreateChatLog` 參數擴充，支援寫入模式與工具清單。
  - BE Controller:
    - `CreateChatLog` 新增接收 `answer_mode`、`used_tools` form 欄位。
    - 對 `used_tools` 做 JSON 驗證與正規化，確保儲存格式一致。
    - 新增 DB 寫入錯誤處理，避免 silent failure。
  - FE Store:
    - AI 回答成功時，`saveChatLog` 一併送出 `answer_mode` 與 `used_tools`。
    - fallback 向量流程也送出 `answer_mode=vector_fallback` 與預設工具標記。
    - `saveChatLog` 擴充為可接收 metadata 參數。

- change-type:
  - Changed

- verification / 驗證結果:
  - Diagnostics:
    - Taipei-City-Dashboard-BE/app/models/chatlog.go: No errors found
    - Taipei-City-Dashboard-BE/app/controllers/chatlog.go: No errors found
    - Taipei-City-Dashboard-FE/src/store/chatStore.js: No errors found
  - Migration 行為:
    - 專案已有 `DBManager.AutoMigrate(&ChatLog{})`，部署啟動時可自動補齊新增欄位。

- impact-risk / 影響與風險:
  - 影響範圍：chatlog 資料結構、前端儲存 payload。
  - 正向影響：可進行模式級監控與品質分析，提升 Agent/RAG 可觀測性閉環。
  - 風險：歷史資料的 `answer_mode`/`used_tools` 會是空值或預設值，做統計時需區分時間區間。

- traceability:
  - Related log: user-added/log/2026-04-17/1054-agent-rag-tool-integration.md
  - Related log: user-added/log/2026-04-17/1056-agent-rag-observability-and-ui-mode-tag.md

- next-actions:
  - P0: 新增統計 API（按日輸出 agent_chat / agent_rag / vector_fallback 比例）。
  - P1: 在管理端面板新增 RAG hit rate 與 tool call trend 圖表。
  - P1: 針對 `used_tools` 做白名單驗證，避免異常值污染報表。