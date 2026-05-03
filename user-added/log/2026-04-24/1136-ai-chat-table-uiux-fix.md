# AI 聊天表格渲染與提示詞修正 / AI Chat Table Rendering and Prompt Guardrails Fix

## 2026-04-24 11:36

- objective:
  - 修正 AI 回覆中表格內容錯位（說明文字被塞進表格列）問題。
  - 優化 AI Studio 聊天區的可讀性與容錯，提升整體 UI/UX。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - 前端新增 Markdown 表格後處理：偵測「僅第一欄有長句、其餘欄空白」的異常列，移出表格並轉為段落顯示。
  - 前端調整表格視覺（間距、陰影、段落跟隨樣式），降低錯位內容造成的閱讀混亂。
  - 後端 ai_studio System Instruction 改為結構化規範，明確要求表格只能放資料列、表格後需空行再寫段落。
  - 後端補強 instruction 注入流程：若請求沒有既有 system message，也會注入完整 instruction，而非簡化版本。

- change-type:
  - Fixed

- technical-details:
  - FE `renderMarkdown` 改為 sanitize 後建立 DOM 節點再做結構修正，最後回傳修正後 HTML。
  - FE 清理規則依據：`tbody tr` 中若第 1 欄為長句且其餘欄位全空，判定為非資料列並轉段落。
  - FE 新增 `.acp__table-followup` 樣式，避免表格外說明與表格樣式混在同一層次。
  - BE `injectInstructions()` 的 Style Guide 重寫，加入表格格式約束與禁忌詞規則。
  - BE `!merged` 分支改為使用完整 `instruction`，確保規則一致。

- verification:
  - 使用 VS Code 問題檢查工具檢查以下檔案無新錯誤：
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
    - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - 人工檢查關鍵程式片段：
    - FE 渲染流程已包含 sanitize -> DOM 清理 -> 回傳 HTML。
    - BE instruction 文字已包含「表格內只能放資料列」與「表格後空一行」。

- performance-impact:
  - FE 新增一次輕量 DOM 掃描，僅在訊息含 `<table` 時觸發，對一般訊息幾乎無成本。
  - 預期使用者閱讀效率提升，減少誤判內容的操作成本。

- impact-risk:
  - 低風險：清理規則以「長句 + 其餘欄位全空」為條件，對正常資料表格影響有限。
  - 邊界情況：若真有合法資料僅填第一欄且文字很長，可能被轉成段落；可依後續實際資料再微調門檻。

- regression-test:
  - 以 AI Studio 查詢產生表格回覆，確認表格列僅保留排名/城市/組件資料。
  - 驗證表格後說明段落不再被包進表格中。
  - 驗證無表格回覆時，文字渲染不受影響。

- traceability:
  - N/A

- next-actions:
  - 建議補一個前端單元測試（或快照測試）針對異常表格列清理邏輯。
  - 建議觀察 3-5 個真實查詢樣本後再微調清理門檻。