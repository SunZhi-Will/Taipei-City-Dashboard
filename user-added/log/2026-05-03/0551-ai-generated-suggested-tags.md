# 建議標籤改為 AI 生成 / Switch Suggested Tags to AI-Generated

## 2026-05-03 05:51

- objective:
  - 讓 AI Chat Bot 與 AI Studio 的建議標籤來源統一為模型輸出，移除前端關鍵字規則式產生。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
- summary:
  - 前端兩個聊天面板改為僅使用後端回傳的 suggested_tags。
  - 移除關鍵字對照表與預設固定標籤 fallback，避免非 AI 產生內容混入建議列。
  - 後端加強 [TAGS] 解析容錯（分隔符標準化、去重、長度過濾、上限 5 個）。
  - 後端系統指令補強：即使不確定也必須輸出 [TAGS] 區塊。
- change-type:
  - Changed
- technical-details:
  - ChatBox 與 AIStudioChatPanel 的 suggestedTags 初始值改為空陣列，watch 流程僅接受 lastBot.suggestedTags。
  - ai_service.go 的 extractSuggestedTags 改為只解析第一組 [TAGS]...[/TAGS] 並使用標準化分隔符（換行、頓號、逗號、分號）。
  - 新增標籤清洗策略：trim、2~12 字元長度限制、去重、最多 5 筆。
  - System Instruction 的 Suggested Tags Rule 增加「不可省略 [TAGS] 區塊」約束。
- verification:
  - 以 Problems 診斷檢查三個修改檔案皆無錯誤：
    - get_errors(Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue) -> No errors found
    - get_errors(Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue) -> No errors found
    - get_errors(Taipei-City-Dashboard-BE/app/services/ai/ai_service.go) -> No errors found
- performance-impact:
  - 前端移除關鍵字規則掃描與陣列組裝，微幅降低每次訊息更新時的計算量。
  - 後端新增標籤清洗僅處理極短字串，效能影響可忽略。
- impact-risk:
  - 若模型未輸出 [TAGS]，前端建議列將不顯示（由規則式 fallback 改為 AI-only 行為）。
  - 已透過系統提示強化要求並保留解析容錯，降低缺失機率。
- regression-test:
  - AI Chat Bot：連續發送 3 種主題問題，確認每次回覆後建議列由模型上下文變化。
  - AI Studio：詢問展示規劃與數據問答兩種情境，確認 suggested_tags 正常顯示與可點擊送出。
  - 無 [TAGS] 模擬：確認 UI 不顯示舊的規則式標籤。
- traceability:
  - N/A
- next-actions:
  - 觀察實際對話中 [TAGS] 缺失率；若仍偏高，可新增後端二階段補生成流程（僅生成 tags）。
