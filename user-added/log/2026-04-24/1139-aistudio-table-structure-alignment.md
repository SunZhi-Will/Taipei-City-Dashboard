# AI Studio 表格結構對齊 ChatBox / Align AI Studio Table Structure with ChatBox

## 2026-04-24 11:39

- objective:
  - 依使用者提供的 HTML 結構，將 AI Studio 聊天表格統一為 `ai-table-wrapper` + `ai-table`，提升一致性與可控性。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 在 Markdown 渲染後處理流程中，將所有 `<table>` 自動補上 `ai-table` class。
  - 若 table 外層沒有 wrapper，會自動包裝成 `<div class="ai-table-wrapper">`。
  - 保留既有異常列清理邏輯（長句誤入第一欄），並在空表時同步移除空 wrapper。
  - SCSS 改為針對 `.ai-table-wrapper` 與 `.ai-table` 定義樣式，不再只依賴裸 `table` 選擇器。

- change-type:
  - Fixed

- technical-details:
  - FE `renderMarkdown()` 內加入 table class/wrapper 標準化流程。
  - 空表清理時增加 parent wrapper 回收，避免殘留空節點。
  - `acp__bot-markdown` 中新增 `.ai-table-wrapper` 與 `.ai-table` 規則，包含邊框、欄線、寬度、溢位與 zebra 行樣式。

- verification:
  - 使用 VS Code 問題檢查：
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue -> No errors found
  - 人工檢查重點：
    - 渲染後 DOM 會產生 `<div class="ai-table-wrapper"><table class="ai-table">...`。

- performance-impact:
  - 僅在含 table 的回覆增加輕量 DOM 包裝與 class 設定，效能影響極低。

- impact-risk:
  - 低風險：變更範圍限定 AI Studio 聊天面板。
  - 若未來有第三方 HTML 直接帶入 table wrapper，會被保留，不會重複包裹。

- regression-test:
  - 測試 AI Studio 查詢產生 Markdown 表格時，結構與樣式是否一致。
  - 測試無表格內容時，一般段落渲染不受影響。

- traceability:
  - N/A

- next-actions:
  - 可將相同 table renderer 抽成共用 util，讓 ChatBox 與 AIStudioChatPanel 完全共用一套邏輯。