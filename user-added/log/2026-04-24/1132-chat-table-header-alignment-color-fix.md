# 表格表頭對齊與顏色修正 / Table Header Alignment and Color Fix

## 2026-04-24 11:32

- objective:
  - 修正聊天表格中表頭與內容對齊不一致（表頭靠左、內容置中）造成閱讀混亂。
  - 移除表頭藍色文字，改為與主題一致的中性文字色。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將第一欄（排名）從置中改為靠左，讓表頭與內容對齊一致。
  - 將表頭文字色由藍色改為白色，提升一致性與可讀性。

- change-type:
  - Fixed

- technical-details:
  - 更新 `th:nth-child(1), td:nth-child(1)` 的 `text-align`：`center -> left`。
  - 更新 `th` 文字色：`#00d4ff -> $white`。

- verification:
  - 使用問題檢查確認修改檔案無錯誤：`get_errors`。
  - 檢視 SCSS 作用範圍，確認只影響聊天 markdown 表格樣式。

- performance-impact:
  - 無顯著效能影響（純 CSS 視覺調整）。

- impact-risk:
  - 低風險；僅涉及聊天表格排版與配色，不影響資料邏輯。

- regression-test:
  - 驗證 3 欄/4 欄表格中，表頭與內容文字對齊一致。
  - 驗證深色主題下表頭文字對比足夠。

- traceability:
  - N/A

- next-actions:
  - N/A
