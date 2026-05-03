# Chat 表格滿寬修正 / Chat Table Full-Width Fix

## 變更摘要 Summary
- 調整 AI 回覆中 markdown 表格樣式，讓表格容器與表格本體都能吃滿訊息區可用寬度。
- 移除導致欄位被過度壓縮的固定表格排版設定，改為自動欄寬分配。
- 保留小螢幕橫向捲動能力，避免內容被裁切。

## 修改檔案 Files Changed
- Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

## 主要調整 Key Changes
1. 在 `.message--plain.message--markdown` 補上 `display: block; width: 100%;`
2. 在 `.ai-table-wrapper` 補上 `inline-size: 100%`、`max-inline-size: 100%`
3. 在 `.ai-table` 改為 `table-layout: auto`，保留 `width/min-width: 100%`
4. 將第 1、2 欄改為緊湊最小寬度策略，最後一欄自動填滿剩餘空間

## 預期效果 Expected Result
- 表格在聊天面板內會視覺上貼齊可用寬度，不再出現看起來只有窄欄位的情況。
- 手機或窄寬容器下仍可水平捲動閱讀。
