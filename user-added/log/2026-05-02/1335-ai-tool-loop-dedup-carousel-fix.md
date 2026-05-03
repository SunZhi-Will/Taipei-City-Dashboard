# AI 工具呼叫去重與輪播不相關元件修正 / AI Tool Call Deduplication & Carousel Relevance Fix

## 2026-05-02 13:35

- objective:
  - **問題一**：AI 思考面板顯示大量重複 tool call（同一查詢被執行 3 次、`get_component_chart_data` 重複 4 次），總延遲高達 21 秒
  - **問題二**：AI Studio 輪播（carousel）fallback 時會顯示與查詢主題無關的元件（例如查 YouBike 卻顯示「雙北空氣品質監測站」）

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js

- summary:
  - **後端**：在 `aiSession` 加入 `seenCallResults map[string]string`，以 `"toolName::args"` 為 key。在 `executeTools()` 執行每個 tool call 前先查此 map；若已存在相同 key 則直接回傳快取結果，不重新呼叫工具，並在 `toolTimeline` 加上 `[cached]` 標記。
  - **前端**：在 `aiStudioChatStore.js` import 加入 `selectFocusedComponents`；當 `display_plan` 為空（fallback 路徑）時，用 `selectFocusedComponents(components, query)` 過濾主題不相關的元件後再傳給 `resolveSceneFromAI`，避免輪播出現偏離主題的組件。
  - **核心原因**：`llama3.3-ffm-70b-16k-chat` 在取得工具結果後仍不斷重複發出相同 tool call，後端迴圈最多跑 5 輪卻缺乏去重機制，導致浪費 API 次數、增加延遲、並干擾 `display_plan` 生成品質。

- change-type:
  - Fixed

- technical-details:
  - `aiSession.seenCallResults`：新增欄位，在 `newSession()` 初始化為空 map
  - 去重 key 格式：`tc.FunctionCall.Name + "::" + tc.FunctionCall.Arguments`（完整字串比對，不同參數不會誤命中）
  - 快取命中時：仍在 `s.currentMessages` 加入 tool response 訊息（保持 LLM 對話歷史一致性），但不呼叫 `tools.Execute()`
  - `toolTimeline` 快取條目的 Result 欄位前綴 `[cached]`，思考面板可依此辨識重複呼叫
  - 前端 fallback 過濾：`selectFocusedComponents` 會對每個組件計算 `computeComponentMatchScore`（關鍵字比對分數），並依 dominant/directIntent 決定保留 2-4 個最相關的組件
  - **注意**：`components` 完整列表仍保留（供 `display_plan` 渲染使用），僅 fallback 路徑的 `resolveSceneFromAI` 呼叫採用過濾後的子集

- verification:
  - `go vet ./app/services/ai/...`：無輸出（無語法錯誤）
  - VS Code 錯誤面板：`ai_service.go` 與 `aiStudioChatStore.js` 均顯示「No errors found」
  - grep 確認：`seenCallResults` 出現在 ai_service.go 的 struct、初始化、去重判斷、結果存入共 4 處；`selectFocusedComponents` 出現在 aiStudioChatStore.js 的 import 與 fallback 呼叫共 2 處

- performance-impact:
  - 理論上單次查詢最多從 5 次重複工具呼叫減少至 1 次，延遲預計從 21s 降低至約 7-10s
  - 每次 API 呼叫節省約 2-4 次重複的 Qdrant 向量搜尋與後端 chart data 查詢

- impact-risk:
  - **範圍**：僅影響 AI chat 功能（`/api/v1/ai/chat`），一般儀表板功能不受影響
  - **去重誤判風險**：key 為完整的 `name::args` 字串，不同查詢參數不會誤命中；同參數重複呼叫確實應被去重
  - **FE fallback 過濾**：`display_plan` 存在時不做過濾，僅 fallback 路徑（AI 生成計畫失敗時）才生效，風險低

- regression-test:
  - [ ] 查詢 YouBike → 確認 toolTimeline 中 `retrieve_components_by_query` 只出現 1 次（第 2 次後應標記 `[cached]`）
  - [ ] 查詢 YouBike → 確認輪播不出現「雙北空氣品質監測站」（除非 display_plan 明確引用）
  - [ ] 查詢空氣品質 → 確認輪播正確顯示空氣品質相關組件
  - [ ] 正常查詢（單次工具呼叫）→ 確認行為與修改前一致

- traceability:
  - N/A（無對應 PR / ticket）

- next-actions:
  - 可考慮在思考面板 UI 針對 `[cached]` 標記的條目顯示灰色樣式，讓使用者更清楚識別去重行為
  - 長期：評估提升 `retrieve_components_by_query` 的相關性篩選閾值（目前 0.78 過低，空氣品質對 YouBike 查詢得到 0.8251 分）
