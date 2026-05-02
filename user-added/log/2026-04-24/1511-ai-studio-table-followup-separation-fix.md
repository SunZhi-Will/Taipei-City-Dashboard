# AI Studio 表格與補充段落分離修正 / AI Studio Table and Follow-up Separation Fix

## 2026-04-24 15:11

- objective:
  - 修正 AI Studio 聊天訊息中，表格與補充說明被包在同一個 ai-table-wrapper 導致視覺黏在一起的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 調整 markdown 轉換流程中補充段落的插入錨點，從 table 改為 table wrapper。
  - 讓補充段落插在 ai-table-wrapper 外層，表格與文字區塊視覺分離。

- change-type:
  - Fixed

- technical-details:
  - 在 extractedParagraphs 處理段落中新增 tableWrapper 變數。
  - 判斷 table 是否位於 ai-table-wrapper 內，若是則以 wrapper 作為插入錨點。
  - paragraph 依序以 afterend 插到 wrapper 後方，不再留在 wrapper 內。

- verification:
  - 使用 get_errors 檢查 Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue，結果無錯誤。
  - 檢視程式碼路徑，確認僅影響表格後續段落的 DOM 插入位置。

- performance-impact:
  - 無顯著效能影響，僅調整 DOM 插入錨點選擇。

- impact-risk:
  - 低風險，僅作用於 AI Studio 聊天 markdown 表格後段落呈現。
  - 若未來 wrapper class 名稱變更，需同步調整判斷條件。

- regression-test:
  - 驗證含表格且有補充句的回覆：補充段落應在表格框外。
  - 驗證無補充句的回覆：表格渲染不受影響。
  - 驗證多段補充句：段落順序維持正確且不包在表格框內。

- traceability:
  - N/A

- next-actions:
  - N/A
