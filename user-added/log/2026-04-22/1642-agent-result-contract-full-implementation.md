# AI 結構化主次結果全面實作 / Full Implementation of Structured Agent Result Contract

## 2026-04-22 16:42

- objective:
  - 將 AI 回應從純文字/工具清單升級為可渲染契約，提供主結果、相關候選與選擇理由。
  - 收斂前端檢索流程，避免多路由 fallback 造成行為漂移。

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/controllers/ai.go
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 後端 `ChatWithTWCC` 改為回傳 `AIChatResult`，新增 `agent_result` 結構（`primary_component`、`related_components`、`selection_reason`、`retrieval_type`）。
  - 在 AI service 解析 `retrieve_components_by_query` 工具輸出，建立主次候選並附上選擇理由。
  - 控制器 `/api/v1/ai/chat/twai` 回應新增 `agent_result` 與新的 `answer_mode=agent_component_selection`（有主結果時）。
  - 前端 `chatStore` 優先使用後端 `agent_result`，再做 `ensureDashboardConfigs` hydration。
  - 前端檢索 fallback 收斂為單一路徑 `POST /vector/component`，移除多端點分叉。
  - UI 新增「主結果/相關候選」之外，再顯示 `selectionReason`，讓選擇可解釋。

- change-type:
  - Changed

- technical-details:
  - `ai_service.go` 新增型別：`AgentComponentCandidate`、`AgentResult`、`AIChatResult`。
  - `buildAgentResult()` 會解析工具回傳 JSON，並以「關鍵詞匹配優先 + 檢索分數」決定主結果與候選。
  - `chatStore.js` 新增 `componentsFromAgentResult()` 與 `fetchDashboardComponentsByVector()`，降低前端推測成本。
  - `ChatBox.vue` 依 `answerMode` 顯示 `Agent + Selection`。

- verification:
  - 靜態診斷：`get_errors` 對以下檔案皆回報 `No errors found`。
    - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
    - Taipei-City-Dashboard-BE/app/controllers/ai.go
    - Taipei-City-Dashboard-FE/src/store/chatStore.js
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - API 呼叫驗證：
    - `POST http://localhost:8080/api/dev/ai/chat/twai`（一般請求）成功回應。
    - `tool_choice` 強制 retrieve 時，回應可見 `tool_used=true` 與 tools 清單。
  - 注意：本機運行中的服務尚未重啟載入新程式時，API 仍可能看不到新 `agent_result` 欄位；需重新部署/重啟後驗證。

- performance-impact:
  - 後端新增 JSON 解析與主次決策邏輯，CPU 開銷輕微。
  - 前端在有 `agent_result` 時可減少額外搜尋分支，整體互動延遲可更穩定。

- impact-risk:
  - 風險：模型若未觸發工具，後端無法產生 `agent_result`。
  - 緩解：前端保留 direct-intent 的向量檢索保底流程。

- regression-test:
  - 驗證查詢「扶養比及老化指數」是否呈現主結果 + 相關候選。
  - 驗證查詢非組件問題時，不應出現不相關卡片。
  - 驗證 `DashboardComponent` 預覽渲染正常且可載入 city 對應 config。

- traceability:
  - user-added/log/2026-04-22/1607-agentic-primary-related-rendering.md

- next-actions:
  - 重啟 BE 容器/服務以套用新控制器回應欄位，並補一次 runtime schema 驗證截圖。
