# 聊天視窗展開改為 UI 放大 / Chat Panel Expand Converted to UI Scaling

## 2026-04-22 15:03

- objective:
  - 修正 ChatBox 展開行為錯誤（彈跳式 modal），改為同一面板放大以對齊 AIChatHub 互動預期。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue
- summary:
  - 將 ChatBox 的展開流程由「Teleport + expand-modal」改為「emit expand 事件給父層」。
  - 展開按鈕改為依狀態切換圖示（展開/縮小），同時更新 aria-label/title。
  - 在 ChatWidgetLauncher 建立 `isChatExpanded`，以 `.chatbox.expanded` 控制尺寸過渡，實現 UI 原地放大。
  - 清除 expand-modal 相關樣式與殘留結構，修正 SCSS 語法破損段落。
- change-type:
  - Fixed
- technical-details:
  - `ChatBox.vue`
  - `defineEmits` 增加 `expand` 事件。
  - `toggleExpand()` 改為同步 emit 布林狀態。
  - 移除 modal 區塊後，修復 `message--button` 被誤植入 template 的 SCSS 結構，恢復按鈕樣式。
  - 補上 `line-clamp: 2` 以搭配 `-webkit-line-clamp`。
  - `ChatWidgetLauncher.vue`
  - 增加 `isChatExpanded` 狀態與 `handleChatExpand()`。
  - `ChatBox` 掛載 `@expand` 事件並以 class binding 套用 `expanded`。
  - 新增 `.chatbox.expanded` 在桌面與小尺寸螢幕的寬高規則與過渡動畫。
- verification:
  - 問題檢查：`get_errors` for `ChatBox.vue` => No errors found。
  - 問題檢查：`get_errors` for `ChatWidgetLauncher.vue` => No errors found。
- performance-impact:
  - 取消 overlay/modal 複製 DOM 結構，減少展開時的重複渲染負擔。
  - 尺寸動畫使用 CSS transition，對主執行緒影響低。
- impact-risk:
  - 依賴 `@expand` 事件傳遞，若未掛載父層處理器會退化為僅圖示切換。
  - 已在目前 launcher 完整接線，風險可控。
- regression-test:
  - 展開按鈕首次點擊：面板寬高放大，非 modal 彈出。
  - 再次點擊：面板恢復原尺寸。
  - 關閉聊天後重新開啟：尺寸應回到預設。
  - 手機版：維持既有全高底部 panel，不應出現 overlay。
- traceability:
  - N/A
- next-actions:
  - 建議新增 E2E 視覺回歸（展開前後尺寸快照）
