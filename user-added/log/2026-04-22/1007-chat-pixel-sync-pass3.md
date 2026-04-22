# 聊天元件像素級同步（第三輪） / Chat Widget Pixel-Level Sync Pass 3

## 2026-04-22 10:07

- objective:
  - 接續「下一步」需求，將 Vue ChatBox 進一步做像素級微調，貼齊 aichathub 的 header、訊息與輸入區交互語言。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - Header action button 補上 hover/active scale 與 cubic-bezier transition。
  - Sticky 公告卡片調整字重、底色、陰影、toggle 按鈕尺寸/hover。
  - Relation table 調整 border、padding、line-height 與 header 背景，提升可讀性並對齊 demo。
  - 訊息文字與氣泡細節微調（line-height、陰影、user max-width）。
  - 輸入框補齊 hover-not-focus 邊框狀態與一致的 transition。
  - 送出按鈕補齊 hover 陰影與過渡曲線。
  - 新增 768 斷點下輸入區 spacing、input padding、send button 尺寸/定位同步。

- change-type:
  - Changed

- technical-details:
  - 對齊 demo 核心 token：
    - header button transition: cubic-bezier(0.4, 0, 0.2, 1)
    - input transition: 0.3s cubic-bezier
    - send button hover shadow: 20/25 + 10/10 組合陰影
  - 針對 sticky 區塊補足可互動 affordance（toggle hover、標題字重/對比）。
  - 針對表格區加入更穩定的視覺層次（border-collapse + neutral gray palette）。

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found

- performance-impact:
  - 僅 CSS 層微調與輕量動畫，不引入額外 runtime 計算，效能影響可忽略。

- impact-risk:
  - 低風險；主要為樣式層調整。可能風險為不同裝置字體渲染差異造成細微視覺偏差。

- regression-test:
  - Header 按鈕 hover/active 手感（clear/close）。
  - Sticky 公告收合與 hover 狀態。
  - Relation table 在多欄位與橫向捲動情境可讀性。
  - 768 以下輸入區與 send button 尺寸定位。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1005-chat-full-sync-pass2.md

- next-actions:
  - 若要最終 1:1，可再做實機截圖比對（desktop/mobile）並依差值做最後一輪 token 校正。
