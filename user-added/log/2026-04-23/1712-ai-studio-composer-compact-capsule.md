# AI Studio 輸入框高度與膠囊樣式修正 / AI Studio Composer Compact Capsule Fix

## 2026-04-23 17:12

- objective:
  - 修正 AI Studio 左側輸入框過高問題
  - 確保輸入框為明確膠囊形狀
  - 不影響右下 ChatBot 的既有外觀

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/chat/ChatComposer.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 在 ChatComposer 新增 `compact` 模式。
  - AI Studio 啟用 `:compact="true"`，將輸入框降高並保持膠囊造型。
  - 右下 ChatBot 不啟用 compact，因此維持原有尺寸。

- change-type:
  - Fixed

- technical-details:
  - `ChatComposer.vue`:
  - props 新增 `compact: Boolean`
  - template 新增 class 綁定：
  - `.input-shell--compact`
  - `.chat-input--compact`
  - `.send-btn--compact`
  - compact 樣式：
  - 輸入框最小高度降為 44px
  - 圓角改為 999px（膠囊）
  - padding 改為 `10px 56px 10px 16px`
  - 發送按鈕縮為 34px

  - `AIStudioChatPanel.vue`:
  - `ChatComposer` 新增 `:compact="true"`

- verification:
  - 檢查方式：編輯器 Problems 診斷
  - 結果：
  - `ChatComposer.vue` 無錯誤
  - `AIStudioChatPanel.vue` 無錯誤

- performance-impact:
  - 無顯著影響，僅樣式與 class 邏輯調整

- impact-risk:
  - 低風險
  - compact 為可選模式，只有 AI Studio 啟用，不影響既有使用者路徑

- regression-test:
  - 進入 `/ai-studio`，確認輸入框高度變低且為膠囊形
  - 測試長文字換行時高度自動增長仍正常
  - 驗證送出按鈕位置和縮放 hover 正常
  - 驗證右下 ChatBot 輸入框未受影響

- traceability:
  - user request: 「阿輸入框怎麼變那麼高 膠囊形狀呢?」

- next-actions:
  - N/A
