# AI 聊天表格防爆寬修正 / AI Chat Table Overflow Fix

## 2026-04-24 11:22

- objective:
  - 修正 AI Studio 聊天訊息中的 Markdown/HTML 表格在長文字情境下爆寬，導致使用者需使用 X 軸捲動才能閱讀。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 調整聊天面板內 Markdown 表格樣式，讓欄寬固定分配並允許儲存格自動換行。
  - 移除 `white-space: nowrap` 的限制，避免長句或異常列內容撐爆整個訊息容器。

- change-type:
  - Fixed

- technical-details:
  - 在 `table` 新增 `table-layout: fixed`，讓欄位依容器寬度平均布局。
  - 在 `th, td` 將 `white-space` 由 `nowrap` 改為 `normal`。
  - 新增 `overflow-wrap: anywhere` 與 `word-break: break-word` 以處理中英文混排與長字串。
  - 新增 `vertical-align: top`，避免多行內容對齊不穩定。

- verification:
  - 以 VS Code diagnostics 檢查檔案語法：`get_errors` 檢查 `AIStudioChatPanel.vue`，結果為 `No errors found`。
  - 針對使用者回報案例（含長句與空白欄位的表格）進行樣式邏輯驗證：儲存格可換行，不再強制單行顯示。

- performance-impact:
  - 僅 CSS 樣式調整，無新增運算流程。
  - 對渲染效能影響可忽略，預期不改變首屏時間與互動延遲。

- impact-risk:
  - 可能使既有表格顯示由單行改為多行，列高增加。
  - 由於目標是避免水平捲動，此變化屬預期且符合可讀性優先策略。

- regression-test:
  - 建議回歸檢查一般短表格是否仍維持可讀排版。
  - 建議在手機與窄視窗下驗證長文字表格不再出現 X 軸捲動。

- traceability:
  - N/A

- next-actions:
  - 若仍有特殊欄位內容（超長 URL/連續字元）導致擠壓，可追加針對 `a` 與 `code` 的表格內斷行規則。
