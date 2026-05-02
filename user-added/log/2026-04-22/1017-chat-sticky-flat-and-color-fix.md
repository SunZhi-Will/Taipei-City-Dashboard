# Chat 公告區塊扁平化與白字修正 / Chat Sticky Notice Flattening and White-Text Fix

## 2026-04-22 10:17

- objective:
  - 修正右下角 ChatBot 置頂公告區塊造成的視覺切邊問題，並修復白底白字的可讀性問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將「置頂公告」由卡片區塊改為扁平樣式（無邊框卡片感），避免放大情境下的邊緣裁切感。
  - 置頂公告區全面指定深色字，避免被全域字色影響導致白底白字。
  - 調整 header/body padding 與 toggle hover 色彩，保留可點擊與可讀性。

- change-type:
  - Fixed

- technical-details:
  - `.sticky-message`
    - 移除 border / border-radius / box-shadow / sticky 定位
    - 改為 `background: transparent` 與 `position: relative`
  - `.sticky-header`
    - 改為透明背景、底部分隔線（dashed）
    - 由卡片內邊距改為水平貼齊內容流
  - `.sticky-body`
    - 透明背景與字色固定
  - 顏色保護
    - 在 `.sticky-message` 下使用 `&, * { color: #27272a !important; }`，防止全域白字污染

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found

- performance-impact:
  - 純 CSS 視覺修正，無額外執行成本。

- impact-risk:
  - 低風險；僅影響公告區塊樣式與顏色，聊天核心流程不受影響。

- regression-test:
  - 展開/收合「置頂公告」
  - 深色主題頁面下公告文字可讀性
  - 低高度視窗放大時公告區塊是否仍正常顯示

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1015-chat-layout-breakage-deep-fix.md

- next-actions:
  - N/A
