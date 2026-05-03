# 變更紀錄：Agent/RAG 可觀測性與模式標記 / Change Log: Agent/RAG Observability and Mode Tagging

## 2026-04-17 10:56

- objective / 目標:
  - 讓前端可辨識本次 AI 回答是否實際使用 RAG 工具。
  - 提升 AI Agent 主流程透明度，避免使用者誤以為是一般聊天回覆。

- files / 修改檔案:
  - Taipei-City-Dashboard-BE/app/controllers/ai.go
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - user-added/log/2026-04-17/1056-agent-rag-observability-and-ui-mode-tag.md

- summary / 變更摘要:
  - BE Controller:
    - 在 `/ai/chat/twai` 回應中新增 `tools`（實際執行的工具清單）與 `answer_mode`（agent_chat / agent_rag）。
    - `answer_mode` 依是否使用 `retrieve_components_by_query` 自動判定。
  - FE Store:
    - `queryByTwai()` 讀取 `answer_mode` 與 `tools`。
    - AI 回覆訊息增加 `answerMode`、`usedTools` 欄位。
    - 回覆內容前綴加入模式標籤 `[Agent]` 或 `[Agent+RAG]`。
  - FE UI:
    - ChatBox 在 bot 訊息中顯示模式膠囊標籤（Agent / Agent + RAG），提升可視化辨識。

- change-type:
  - Changed

- verification / 驗證結果:
  - Diagnostics:
    - Taipei-City-Dashboard-BE/app/controllers/ai.go: No errors found
    - Taipei-City-Dashboard-FE/src/store/chatStore.js: No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue: No errors found
  - 邏輯檢查:
    - 後端已回傳 mode + tools 給前端。
    - 前端已可在回覆中顯示 Agent/Agent+RAG 模式資訊。

- impact-risk / 影響與風險:
  - 影響範圍：AI chat 回傳契約與聊天 UI 呈現。
  - 正向影響：提高可追溯性、可觀測性與使用者信任。
  - 風險：若未來工具命名調整，`answer_mode` 判定需同步維護。

- traceability:
  - Related log: user-added/log/2026-04-17/1054-agent-rag-tool-integration.md

- next-actions:
  - P0: 將 `answer_mode` 與 `tools` 寫入 chatlog 結構化欄位，便於分析。
  - P1: 建立 Dashboard 指標（RAG hit rate、tool call ratio、fallback rate）。
  - P1: 增加「引用來源/組件」區塊，讓 RAG 回答可直接導向資料元件。