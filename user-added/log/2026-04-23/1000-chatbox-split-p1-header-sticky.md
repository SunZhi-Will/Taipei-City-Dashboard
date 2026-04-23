# ChatBox 拆分 P1（Header/Sticky） / ChatBox Split P1 (Header/Sticky)

## 2026-04-23 10:00

- objective:
  - 延續 ChatBox 拆分，將頁首與置頂公告從容器元件分離，進一步降低單檔複雜度。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatHeader.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatStickyNotice.vue
- summary:
  - 新增 ChatHeader 子元件承接清除歷史、展開、關閉按鈕與 header 視覺樣式。
  - 新增 ChatStickyNotice 子元件承接置頂公告開合與公告樣式。
  - ChatBox 改為容器組裝：以事件綁定取代內嵌 header/sticky 模板與方法。
  - 清除 ChatBox 內已搬移的 header/sticky 樣式與未使用的 slideDown keyframes。
- change-type:
  - Changed
- technical-details:
  - ChatHeader emits: clear/expand/close。
  - ChatStickyNotice 採 v-model(modelValue) 進行公告開合狀態同步。
  - ChatBox 行數由 837 降至 631（再減少 206 行）。
  - 新增子元件行數：ChatHeader 110 行，ChatStickyNotice 120 行。
- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatHeader.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatStickyNotice.vue
  - 結果：三個檔案均 No errors found。
  - 使用行數檢查指令：
    - Get-Content "Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue" | Measure-Object -Line
    - Get-Content "Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatHeader.vue" | Measure-Object -Line
    - Get-Content "Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatStickyNotice.vue" | Measure-Object -Line
- performance-impact:
  - 執行效能預期近似。
  - 維運效能提升：降低單檔認知負擔與衝突面，利於平行開發。
- impact-risk:
  - 風險：因 scoped style 移至子元件，視覺細節（邊距、hover）可能有微小差異。
  - 邊界：公告 sticky 行為需在長內容對話場景手動確認。
  - 降級策略：如樣式差異不可接受，可暫時回遷樣式到父元件並保留結構拆分。
- regression-test:
  - 驗證項目：
    - Header 三按鈕（清除/展開/關閉）皆可觸發原行為。
    - 置頂公告可開合且 aria-expanded 正確變化。
    - 聊天內容捲動與輸入區位置不受影響。
- traceability:
  - 相關前一筆：user-added/log/2026-04-23/0958-chatbox-split-p0.md
- next-actions:
  - P1 後續：拆出 ChatMessageList，目標將 ChatBox 降至 400 行以下。
