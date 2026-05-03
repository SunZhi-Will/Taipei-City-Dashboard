# AI Studio 聊天表格樣式生效修正 / AI Studio Chat Table Style Apply Fix

## 2026-04-24 14:47

- objective:
  - 修正 AI Studio 右側 AI Chat 中 markdown 表格未套用預期樣式，導致看起來未滿版的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 將 `.ai-table-wrapper`、`.ai-table`、`.acp__table-followup` 改為 `:deep(...)` 選擇器，確保 `v-html` 動態內容在 `scoped` 樣式下可被命中。
  - 同步套用與主聊天一致的滿版欄寬策略（前兩欄固定、最後一欄吃滿）。
  - 加強表格邊框可視性，維持左對齊與中性表頭色。

- change-type:
  - Fixed

- technical-details:
  - `:deep(.ai-table-wrapper)` 維持 `width/min-width/inline-size: 100%`。
  - `:deep(.ai-table)` 調整為 `table-layout: fixed`。
  - 邊框調整：外框 `rgba(255,255,255,0.28)`、儲存格 `rgba(255,255,255,0.22)`。
  - 欄寬策略：第 1 欄 `56px`、第 2 欄 `84px`、最後一欄 `calc(100% - 140px)`。

- verification:
  - 對修改檔案執行 `get_errors`，結果為無錯誤。
  - 檢查樣式區塊語法與選擇器作用範圍正常。

- performance-impact:
  - 無顯著效能影響（僅 CSS 命中與排版規則調整）。

- impact-risk:
  - 低風險；變更只作用於 AI Studio 聊天 markdown 呈現。

- regression-test:
  - 驗證 AI Studio 右側聊天中 3 欄表格可滿版。
  - 驗證欄線可見、表頭與內容對齊一致、表頭文字非藍色。
  - 驗證窄螢幕下橫向捲動仍可使用。

- traceability:
  - N/A

- next-actions:
  - N/A
