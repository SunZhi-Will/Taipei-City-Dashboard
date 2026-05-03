# 聊天表格欄線可視性修正 / Chat Table Gridline Visibility Fix

## 2026-04-24 11:30

- objective:
  - 解決 AI 對話表格欄位分隔線過淡，使用者難以辨識欄位邊界的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 強化表格外框與儲存格邊框透明度，讓直欄與橫列邊界可清楚辨識。
  - 同步提升表頭底色對比，並保留斑馬紋背景輔助閱讀。

- change-type:
  - Fixed

- technical-details:
  - 在 `.ai-table` 新增外框：`border: 1px solid rgba(255,255,255,0.28)`。
  - 將 `th, td` 從單純 `border-bottom` 改為四邊框：`border: 1px solid rgba(255,255,255,0.22)`。
  - 調整 `th` 背景為 `rgba(255,255,255,0.09)`，提高表頭視覺分隔。
  - 使用 `tr:nth-child(even) td` 保留偶數列微底色，提升列閱讀性。

- verification:
  - 執行 VS Code 問題檢查：`get_errors`，目標檔案無錯誤。
  - 檢查樣式區塊語法完整，無遺漏括號與衝突選擇器。

- performance-impact:
  - 僅調整 CSS 色彩與邊框樣式，對渲染效能影響可忽略。

- impact-risk:
  - 風險低，僅影響 AI 對話 markdown 表格樣式。
  - 若主題色日後變更，可能需再微調透明度以維持對比。

- regression-test:
  - 驗證 3 欄與 4 欄以上表格皆可顯示明確直欄線。
  - 驗證深色背景下 header/body 欄位分隔可辨識。
  - 驗證窄螢幕下橫向捲動與線條顯示正常。

- traceability:
  - N/A

- next-actions:
  - P2：若要再提升可讀性，可加入欄位 hover 高亮（column highlight）作為下一步。
