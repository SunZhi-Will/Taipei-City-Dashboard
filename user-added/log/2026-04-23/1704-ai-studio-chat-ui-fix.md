# AI Studio 聊天輸入與標籤體驗修正 / AI Studio Chat Input and Tag UX Fix

## 2026-04-23 17:04

- objective:
  - 修正 AI Studio 左側聊天區的三個可用性問題：
  - 發送按鈕不明顯
  - Tag 區缺少左右捲動按鈕
  - 輸入框視覺上過度靠右貼邊

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 將 AI Studio 左側聊天面板改為共用既有的 `ChatComposer` 與 `SuggestedTagsBar` 元件。
  - 透過共用元件直接補齊：
  - 發送按鈕外觀與互動一致
  - Tag 左右箭頭捲動控制
  - 輸入區左右邊距與內距一致
  - 調整訊息區底部 padding，避免內容被底部輸入區覆蓋。

- change-type:
  - Fixed

- technical-details:
  - import 調整：
  - 新增 `ChatComposer`、`SuggestedTagsBar`
  - 移除 `SendIcon` 直接組裝方式
  - template 調整：
  - 將舊的 `acp__tags` + 手寫 tag 按鈕改成 `SuggestedTagsBar`
  - 將舊的 `acp__composer` + textarea/button 改成 `ChatComposer`
  - style 調整：
  - `acp__messages` padding 改為 `12px 14px 154px`，預留底部輸入與 tag 區空間
  - 移除不再使用的 `acp__tags`、`acp__tag`、`acp__composer`、`acp__input`、`acp__send` 區塊

- verification:
  - 檢查方式：使用編輯器 Problems 診斷
  - 結果：`AIStudioChatPanel.vue` 無錯誤（No errors found）
  - 檢查方式：檔案內容比對
  - 結果：已看到 `SuggestedTagsBar` 與 `ChatComposer` 在 template 中生效

- performance-impact:
  - 幾乎無效能衝擊
  - 只做元件組裝替換與樣式空間調整，無新增高成本運算

- impact-risk:
  - 低風險
  - 僅修改 AI Studio 左側聊天面板，不影響右下 ChatBot store 邏輯
  - 潛在風險：由於共用元件樣式更完整，局部間距會和舊版略有差異

- regression-test:
  - 打開 `/ai-studio`，確認可見發送按鈕
  - 在 tag 過多時，確認左右箭頭顯示並可捲動
  - 輸入多行文字，確認輸入框不貼邊且按鈕不重疊
  - 送出訊息後，確認聊天內容不被底部區塊遮擋

- traceability:
  - user request: 「發送按鈕呢 Tag的左右按鈕呢 為啥輸入框那麼靠右邊邊線」

- next-actions:
  - N/A
