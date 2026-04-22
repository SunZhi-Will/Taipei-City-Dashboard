# 變更紀錄：Agent 串接 RAG 工具主流程 / Change Log: Agent RAG Tool Integration into Primary Flow

## 2026-04-17 10:54

- objective / 目標:
  - 將既有 Qdrant 向量檢索（RAG）從 fallback 機制升級為可由 AI Agent 主流程直接調用。
  - 使 AI 回答不僅為一般聊天，而是具備「工具調用 + 檢索增強」能力。

- files / 修改檔案:
  - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - user-added/log/2026-04-17/1054-agent-rag-tool-integration.md

- summary / 變更摘要:
  - BE: 新增 `retrieve_components_by_query` 工具註冊，允許模型在 tool-calling loop 中直接呼叫向量檢索。
  - BE: 新增 `ComponentRetrieveArgs` 參數結構，標準化 query/limit/score。
  - BE: 新增 `RetrieveComponentsByQuery()` 實作，重用既有 `models.GetComponentByQueryVector()`，並回傳 JSON 化結果給 LLM。
  - FE: 在 `/ai/chat/twai` payload tools 中新增 `retrieve_components_by_query` schema。
  - FE: 調整 system prompt，明確要求城市資料問題優先檢索再回答。

- change-type:
  - Changed

- verification / 驗證結果:
  - Diagnostics:
    - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go: No errors found
    - Taipei-City-Dashboard-FE/src/store/chatStore.js: No errors found
  - 架構檢查:
    - Agent tool registry 已可調用 RAG 檢索能力。
    - 前端已將 RAG tool schema 送入 AI chat 請求。

- impact-risk / 影響與風險:
  - 影響範圍：AI 對話工具能力、前端工具宣告策略。
  - 正向影響：AI 回答可直接帶入向量檢索結果，提升可驗證性與任務導向能力。
  - 風險：
    - 若模型未主動觸發該工具，仍可能回到一般文字回答。
    - 檢索 score/limit 預設值可能需再以實際對話資料微調。

- traceability:
  - N/A

- next-actions:
  - P0: 在 ai_service 增加檢索觸發監測（tool call ratio）與失敗原因記錄。
  - P1: 在 FE 對話 UI 顯示「本次回答是否使用 RAG 工具」。
  - P1: 依實際查詢分布調整 score/limit 預設參數。