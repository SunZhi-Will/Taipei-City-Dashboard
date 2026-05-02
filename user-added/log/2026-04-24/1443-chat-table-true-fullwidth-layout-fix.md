# 聊天表格滿版欄寬修正 / Chat Table True Full-Width Layout Fix

## 2026-04-24 14:43

- objective:
  - 修正 AI 聊天表格在 3 欄情境下視覺未滿版的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 由自動欄寬改為固定表格版面，確保表格會使用完整可用寬度。
  - 第一、二欄設為固定窄寬，最後一欄指定為剩餘空間，避免看起來縮在左側。
  - 維持表頭與內容一致左對齊及中性表頭文字色。

- change-type:
  - Fixed

- technical-details:
  - `.ai-table`：`table-layout: auto -> fixed`。
  - `th, td`：補上 `text-align: left`，避免欄位對齊不一致。
  - 第 1 欄寬度設為 `56px`，第 2 欄寬度設為 `84px`。
  - 最後一欄改為 `width: calc(100% - 140px)`，明確吃滿剩餘寬度。

- verification:
  - 針對修改檔案執行 `get_errors`，結果無錯誤。
  - 檢查 CSS 選擇器作用範圍僅限聊天 markdown 表格區塊。

- performance-impact:
  - 無顯著效能影響（純 CSS 版面配置調整）。

- impact-risk:
  - 低風險；僅影響對話表格視覺呈現。
  - 若未來表格欄數變動大，可能需再調整固定欄寬策略。

- regression-test:
  - 驗證 3 欄（排名/城市名/組件名）時最後一欄可視覺滿版。
  - 驗證窄螢幕下仍可水平捲動且不裁切內容。

- traceability:
  - N/A

- next-actions:
  - P2：可改為以 `colgroup` 動態欄寬策略，提升不同欄數的自適應能力。
