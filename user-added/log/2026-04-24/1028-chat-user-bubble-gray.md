# 使用者對話雲灰底與非滿版修正 / Fix User Chat Bubble Gray Style and Non-Full-Width Layout

## 2026-04-24 10:28

- objective:
  - 修正聊天訊息中使用者輸入泡泡視覺，避免看起來滿版，並將深藍底改為灰色。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 將使用者對話雲由深藍底改為灰色，符合需求中的視覺方向。
  - 調整使用者泡泡容器排版行為，避免內容區塊撐滿整行，改為依內容寬度呈現。
  - 同步調整一般聊天視窗與 AI Studio 聊天面板，避免不同入口樣式不一致。

- change-type:
  - Fixed

- technical-details:
  - 在 ChatBox 使用者訊息樣式新增 `display: inline-block` 與 `max-width: 100%`，並將 `.user .content` 改為 `width: auto`、`flex: 0 1 auto`、`align-items: flex-end`，避免 user bubble 因父層 `width: 100%` 造成視覺滿版。
  - 在 ChatBox 將 `.message--bubble` 背景從 `#2a3f52` 改為 `#6b7280`。
  - 在 AIStudioChatPanel 將 `.acp__user-bubble` 設為 `display: inline-block`，並把漸層深藍背景改為 `#6b7280`。

- verification:
  - 執行診斷檢查：`get_errors` 針對兩個修改檔案皆回報 `No errors found`。
  - 人工檢查點：
    - 使用者訊息泡泡是否為灰色底。
    - 使用者訊息是否不再視覺滿版，長短訊息寬度可隨內容縮放。
    - 一般聊天與 AI Studio 兩處樣式是否一致。

- performance-impact:
  - 僅 CSS 樣式調整，無額外渲染邏輯與資料請求。
  - 預期效能影響可忽略（接近 0）。

- impact-risk:
  - 低風險：僅影響使用者訊息泡泡視覺樣式。
  - 可能邊界：超長無空白字串在窄螢幕下仍可能接近最大寬度，但不應滿版。

- regression-test:
  - 驗證桌機與手機視窗下的 user bubble 寬度與背景色。
  - 驗證 bot 訊息卡片、表格與按鈕區塊樣式未被影響。
  - 驗證對話輸入、送出與滾動到底行為正常。

- traceability:
  - N/A

- next-actions:
  - 若需更淺灰可再調整為 token 化色票（例如使用全域 CSS 變數），以便後續主題統一管理。
