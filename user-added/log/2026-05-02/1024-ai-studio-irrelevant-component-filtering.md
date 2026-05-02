# AI Studio 無關組件過濾 — 雙層防禦 / AI Studio Irrelevant Component Filtering - Dual-layer Defense

## 2026-05-02 10:24

- objective:
  - 用戶展示「空氣品質」查詢結果中仍出現「電動巴士比例」、「自行車路網統計資料」、「全市年齡分區」等完全無關的組件
  - 根本原因：AI LLM (TWAI) 直接把向量搜尋的全部結果填入表格，沒有自行判斷相關性；前端 buildComponentNarrative 在 genericAiReply=false 時也直接輸出 AI 原始文字
  - 需要雙層防禦：(1) AI 端自行過濾、(2) 前端偵測過包含時重建敘述

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **[Layer 1 - System Prompt] AI 自行過濾無關組件**
    - 在 `buildTwaiMessages` 的系統提示詞中加入：「在決定要列入表格的組件前，請先自行判斷：每個工具回傳的組件是否與使用者查詢的主題直接相關；明顯不相關的組件（例如查「空氣品質」卻出現「電動巴士」、「自行車」、「人口分布」等）一律省略，不列入表格也不在回覆文字中提及。」
    - 利用 LLM 本身的語意理解能力，在生成回覆前主動排除無關組件，這是「AI思考」的核心
    - 同時修正觸發條件：原本「組件推薦時若有 2 筆以上結果就用表格」→ 改為「達條件且有 2 筆以上相關結果才用表格」

  - **[Layer 2 - Frontend] extractValueFromTable + tableIsOverInclusive 偵測**
    - 新增 local helper `extractValueFromTable(aiContent, componentName)`：
      - 解析 AI 回覆中的 Markdown pipe 表格
      - 按表格格式（排名｜城市名｜**組件名**｜數值）的第 3 欄比對組件名稱
      - 若找到匹配的 row，回傳第 4 欄的數值字串（例如 "39.5"）
    - `tableIsOverInclusive` 偵測邏輯：
      - 計算 AI 表格中的 data row 數（排除 header row 和 separator row）
      - 若 `aiTableDataCount > list.length`（AI 表格 > 我們已過濾的組件數），判定為「過包含」
    - 當 `genericAiReply || tableIsOverInclusive` 為 true：
      - 嘗試從 AI 表格中擷取 primary 組件的實際數值（保留有用的 39.5 等數值）
      - 重建為乾淨敘述：「您好！根據您關於「...」的查詢，為您找到最相關的指標：**組件名**（最新數值：V）：短描述。」
      - 附加 keywordRelated 延伸推薦 + 結語

  - **設計精妙之處**：當 AI 成功自行過濾（Layer 1 生效），表格 row 數會與 list.length 相符 → tableIsOverInclusive=false → 使用 AI 原始回覆（有完整敘述和數據）；只有當 AI 仍然過包含時，Layer 2 才介入重建，並嘗試搶救 primary 組件的數值。

- change-type:
  - Fixed

- technical-details:
  - `extractValueFromTable` 用 `/^\|[^\n]+\|$/gm` 找所有 pipe row，過濾 `/^\|[\s|:-]+\|$/` 排除 separator，再 `.slice(1)` 去除 header。對每個 data row 按 `|` 分割、trim，取 cells[2] 比對組件名，cells[3] 為數值
  - `allPipeRows.filter(row => !/^\|[\s|:-]+\|$/.test(row))` 中，`[\s|:-]+` 匹配空白、`|`、`:`、`-`，精確排除 separator row（`| --- | --- |`）而不影響有中文的 content row
  - 重建敘述使用 `\n\n` 作為分隔符（換行顯示），與前段的 `' '` 分隔方式不同，讓視覺上更清楚
  - 系統提示詞增加約 80 tokens，仍在 llama3.3-ffm-70b-32k 的 context window 範疇內

- verification:
  - `get_errors` 對 aiChatService.js 回報 No errors found
  - 邏輯驗證：
    - 空氣品質查詢 → 空氣品質監測站 matchScore ≈ 128，電動巴士 ≈ 7.8；dominant=true → list.length=2（含延伸）或 1（若只 primary）；AI 若仍回傳 4 rows → tableIsOverInclusive=true → 重建
    - AI 若成功自行過濾只回傳 1 row → tableIsOverInclusive=false → 使用 AI 完整回覆 ✓
  - 確認 extractValueFromTable 對 `| 1 | 雙北 | 雙北空氣品質監測站 | 39.5 |` 正確解析出 "39.5" ✓

- performance-impact:
  - 正規表達式操作在小型 AI 回覆字串（< 2KB）上可忽略

- impact-risk:
  - 若 AI 表格格式不符（非標準 pipe table，或欄位順序不同）：extractValueFromTable 回傳 null → valuePart 為空 → 敘述仍正確，只是少了數值，屬 graceful degradation
  - tableIsOverInclusive 誤判場景：若使用者查詢本身有多個主題（如「空氣品質與交通」），正常情況下 list.length 應 ≥ 2，降低誤判機率
  - 系統提示詞新增指令可能讓 AI 在某些邊界情況（明明相關但被誤判省略）過度保守 → 此為 Layer 1 的局限，Layer 2 仍能確保至少顯示 primary 組件

- regression-test:
  - 測試：「空氣品質」→ 確認結果只有空氣品質相關組件，無電動巴士/自行車/年齡分區
  - 測試：「空氣品質與交通」→ 確認兩個主題的組件都出現
  - 測試：extractValueFromTable("...| 1 | 雙北 | 雙北空氣品質監測站 | 39.5 |\n...", "雙北空氣品質監測站") === "39.5"
  - 測試：AI 只回傳 1-2 筆相關組件（Layer 1 生效）→ tableIsOverInclusive=false → 使用 AI 原始回覆

- traceability:
  - 用戶回饋：2026-05-02 session，兩筆「空氣品質」查詢截圖
  - 關聯 log：user-added/log/2026-05-02/0955-ai-studio-response-quality-fix.md

- next-actions:
  - 觀察幾次實際查詢，確認 Layer 1 生效率（AI 是否真的開始自行過濾）
  - 若 Layer 1 生效率 < 80%，考慮在後端 `ai_service.go` 的工具呼叫後對 agent_result 做程式化過濾
