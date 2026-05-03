# AI 智慧升級 / AI Intelligence Upgrade

## 2026-05-02 10:56

- objective:
  - 深度分析專案 AI 功能後，修正多個限制 AI 品質的關鍵問題，使 AI 回覆更完整、AI Studio 展示更豐富

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/services/ai/providers/twcc/twcc.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **[Bug Fix] hero 投影片被靜默丟棄**：`normalizeDisplayPlan` 的 `allowedType` 只含 `component` / `map`，導致 AI 依指示生成的 `hero` 與 `component_explain` 型投影片在 normalize 階段全數被 `continue` 跳過。FE `AIStudioPresentationCanvas.vue` 已能正確渲染這兩種型別，因此直接將其加入白名單。
  - **[Improvement] 回覆 token 上限從 512 → 1500**：前端 `createPayload` 中 `max_new_tokens` 原為 512（有歷史時）/256（無歷史時）。512 tokens 約等於 250-300 個中文字，一張 5 列 Markdown 表格就會截斷。改為 1500/700，確保完整表格與段落能一次輸出。後端 `TWCC.MaxTokens` 同步從 350 → 1500 作為防護預設值。
  - **[Improvement] 工具描述大幅強化**：四個工具的 `description` 從一句話改為詳細說明「何時呼叫」、「參數含義」、「依賴關係」，直接影響 LLM 的 function calling 決策品質。特別強調 `retrieve_components_by_query` 必須先於 `get_component_chart_data` 呼叫，以及零結果時的重試策略（降低 score 至 0.72）。
  - **[Improvement] 零結果幻覺防護**：前後端 system prompt 均新增「若 retrieve 回傳空結果，不可捏造組件或數值，需直接告知使用者並建議換詞」的明確指示，防止 AI 在找不到相關組件時生成虛假資訊。
  - **[Improvement] AI Studio 溫度與 Prompt 優化**：AI Studio 模式溫度從固定 0.35 → 0.5，提升展示敘事的多樣性。Backend system prompt 中新增 `component_explain` 投影片類型的使用說明與完整 JSON 範例（含 hero 開場、解說頁、hero 結尾的完整敘事弧線）。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `normalizeDisplayPlan`：`allowedType` map 新增 `"hero": true` 與 `"component_explain": true`；hero/component_explain 投影片的 `focus_component_id` 為 0 是預期行為，FE 的 `getSlideComponent` 會返回 null，渲染路徑走 `slide-info--hero` class，不需要 dashboardConfig。
  - `TWCC.MaxTokens` 雖在當前代碼路徑中未被 `toTWCCParameters` 直接讀取（改從 metadata 讀），但作為結構體預設值存在，防止未來代碼路徑變更時 fallback 至過低的值。
  - AI Studio prompt 中的 JSON 範例從非合法 JSON（含「或」字樣的偽代碼）改為完整可解析的 JSON block，降低 LLM 解析錯誤率。
  - `buildTwaiMessages` 的 systemPrompt 改用字串串接而非單一超長字串，提升可讀性與未來可維護性。

- verification:
  - `get_errors` 工具驗證三個修改檔案均無編譯/lint 錯誤
  - `normalizeDisplayPlan` 邏輯：hero slide 不進入 `!allowedType[t]` 分支，不再被 continue 跳過

- performance-impact:
  - max_new_tokens 1500 vs 512：每次 AI 呼叫的 LLM 計算成本提升約 2-3 倍（token 生成是主要耗時），但對使用者而言回覆品質顯著改善，避免截斷重試的隱性成本
  - 工具描述字串增長（約 +1200 tokens 進 prompt）：每次呼叫的 input tokens 增加，可接受

- impact-risk:
  - hero/component_explain 加白名單：低風險。FE 早已支援這兩種型別，僅是移除了 BE 的誤判過濾。
  - token 上限提升：若 TWCC API 有 token 配額限制，高峰期成本略增；已有 semaphore 限流機制保護。
  - AI Studio 溫度 0.5：對嚴格數據問答場景影響極小（0.35 與 0.5 差異不顯著），但可能在少數邊緣情境產生略微不同的措辭。

- regression-test:
  - AI Studio：輸入「幫我展示臺北交通議題」，確認生成的 display_plan 包含 hero 開場投影片，且前端正確渲染為標題畫面而非空白
  - 一般聊天：輸入一個明確無組件的查詢（如「月球表面溫度」），確認 AI 回覆「找不到相關組件」而非幻覺出組件
  - 長回覆截斷測試：要求「列出所有空氣相關組件並說明」，確認回覆不被截斷在表格中間

- traceability:
  - N/A

- next-actions:
  - 中優先：`vector_client.go` 的 Vue 組件 indexer 使用 hash 偽造向量（MVP placeholder），需替換為真實 ONNX embedding 才能啟用 `components` 集合的搜尋功能
  - 低優先：考慮加入 AI 回覆的串流（streaming）支援到一般聊天模式，改善大型回覆的體驗感
