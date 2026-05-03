# 全面實作：雙 AI 核心精簡與追蹤強化 / Full Implementation: Dual AI Core Simplification and Traceability

## 2026-04-24 15:35

- objective:
  - 完成雙 AI 通道（Chat Widget + AI Studio）核心整合與精簡，降低重複程式碼。
  - 提升 TWAI 對話 session 穩定性與後端工具呼叫可追溯性。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/controllers/ai.go

- summary:
  - Chat Widget 與 AI Studio store 均改為共用 aiChatService 核心流程，保留各自模式差異（如 app_mode 與 scene 行為）。
  - aiChatService 新增 per-tab 穩定 session id（twai_session_id），避免日期型 session 導致會話混用。
  - 後端 ai_service 新增 tool_timeline（name/args/result），並以 latestToolResult 建立 agent_result，避免同名工具覆蓋造成訊息遺失。
  - controller ai.go 回傳 tool_timeline，前端/管理端可直接觀測工具執行鏈。

- change-type:
  - Changed

- technical-details:
  - FE
    - chatStore.js：刪除冗長重複函式，保留既有對外 API（chatData/isResponding/addChatData/addQueryData/saveChatLog/clearChatHistory）。
    - aiStudioChatStore.js：同步採用精簡模式，保留 displayPlan + presentation scene 合成邏輯。
    - aiChatService.js：新增 TWAI_SESSION_KEY、createRandomSessionPart、getTwaiSessionId，createPayload.session 改由 getTwaiSessionId() 產生。
  - BE
    - ai_service.go：新增 ToolExecution、AIChatResult.ToolTimeline、aiSession.toolTimeline、latestToolResult、copyToolTimeline。
    - ai.go：response data 加入 tool_timeline。

- verification:
  - get_errors 檢查通過（No errors found）：
    - Taipei-City-Dashboard-FE/src/store/chatStore.js
    - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js
    - Taipei-City-Dashboard-FE/src/services/aiChatService.js
    - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
    - Taipei-City-Dashboard-BE/app/controllers/ai.go

- performance-impact:
  - FE：顯著減少重複程式碼與重複請求流程維護成本；執行效能預期中性至小幅提升。
  - BE：新增 timeline 記錄為輕量 append 操作，成本可接受，換取可觀測性提升。

- impact-risk:
  - 前端 store 內部重構可能影響隱性依賴（若有外部直接引用內部私有函式）。
  - 新增 tool_timeline 屬非破壞性擴充，不影響既有 consumer。

- regression-test:
  - Chat Widget：一般提問、組件推薦、建立儀表板。
  - AI Studio：提問後 scene/displayPlan 輸出、presentation 切換。
  - 服務異常：TWAI 失敗後向量 fallback。
  - API：/api/v1/ai/chat/twai 回傳 tools + tool_timeline + agent_result 一致性。

- traceability:
  - log: user-added/log/2026-04-24/1527-雙-ai-通道核心精簡整合-ai-dual-channel-core-consolidation.md

- next-actions:
  - N/A
