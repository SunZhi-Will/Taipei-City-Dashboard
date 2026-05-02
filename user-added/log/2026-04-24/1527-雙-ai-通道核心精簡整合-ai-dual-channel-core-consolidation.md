# 雙 AI 通道核心精簡整合 / AI Dual-Channel Core Consolidation

## 2026-04-24 15:27

- objective:
  - 將 Chat Widget 與 AI Studio 的聊天核心邏輯做最小但完整的整合，降低重複程式碼與維護成本。
  - 補強 TWAI session 識別策略與後端工具呼叫可追溯性。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - 以共用 aiChatService 為核心，重寫 chatStore 為精簡版流程，移除大量重複函式與內嵌 API 實作。
  - TWAI payload 的 session 從「日期型」改為「單分頁穩定隨機 session」，避免不同對話混用同一 session。
  - 後端新增 tool_timeline，保留每次工具呼叫參數與結果；agent_result 改用最後一次 retrieve_components_by_query 的結果，避免同名工具覆蓋帶來的判讀誤差。

- change-type:
  - Changed

- technical-details:
  - FE store:
    - chatStore 保留既有對外 API（chatData/isResponding/addChatData/addQueryData/saveChatLog/clearChatHistory）。
    - addQueryData 仍維持 TWAI 優先、向量 fallback；UI 所需欄位（button/relations/scene/components）完整保留。
  - FE service:
    - 新增 TWAI_SESSION_KEY、createRandomSessionPart、getTwaiSessionId。
    - queryByTwai.createPayload.session 改為 getTwaiSessionId()。
  - BE service:
    - 新增 ToolExecution 與 AIChatResult.tool_timeline。
    - aiSession 新增 toolTimeline 並於 executeTools 持續 append。
    - finalize 使用 latestToolResult("retrieve_components_by_query") 建立 agentResult。
    - 新增 copyToolTimeline 供 API 回傳不可變副本。

- verification:
  - 以 VS Code diagnostics 檢查三個修改檔案：
    - get_errors(Taipei-City-Dashboard-FE/src/store/chatStore.js) -> No errors found
    - get_errors(Taipei-City-Dashboard-FE/src/services/aiChatService.js) -> No errors found
    - get_errors(Taipei-City-Dashboard-BE/app/services/ai/ai_service.go) -> No errors found
  - 透過靜態程式檢視確認 chatStore 對外介面未變更，ChatBox/Launcher 不需同步改碼。

- performance-impact:
  - FE：減少重複邏輯與函式定義，預期降低維護與認知成本；執行時效能影響中性偏正向。
  - BE：新增 tool_timeline 寫入為 O(n tool calls)，對單次請求影響輕微；換得較高可觀測性與可除錯性。

- impact-risk:
  - 若既有流程曾依賴 chatStore 內部舊私有函式（未對外暴露），該耦合已移除，需注意隱性依賴。
  - 後端 API 新增欄位 tool_timeline 為非破壞性；前端未使用時不影響既有渲染。

- regression-test:
  - 建議手動測試：
    - Chat Widget：一般提問、組件推薦、建立儀表板按鈕。
    - AI Studio：提問後 scene/components 渲染、輪播模式切換。
    - 斷網或 5xx 情境下是否正確走向量 fallback。
  - 建議 API 測試：
    - POST /api/v1/ai/chat/twai 驗證回傳 tools/tool_timeline/agent_result 一致性。

- traceability:
  - related files only, no PR/commit yet

- next-actions:
  - P1: 將 aiStudioChatStore 進一步抽象為可重用 composable，讓兩個 store 僅保留模式差異。
  - P1: 在 admin-ai-stats 增加 tool_timeline 聚合指標（工具次數、失敗率、平均延遲）。
