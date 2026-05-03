# 使用者訊息對話雲樣式修正 / User Message Bubble Style Fix

## 2026-04-23 17:10

- objective:
  - 讓 AI Studio 左側聊天中的「使用者訊息」明確顯示為對話雲

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 強化 `.acp__user-bubble` 的視覺層次，改為深色漸層背景、較明顯邊框、陰影與更清楚的圓角。
  - 避免原本依賴主題變數透明度可能造成的泡泡不明顯問題。

- change-type:
  - Fixed

- technical-details:
  - `.acp__user-bubble` 調整如下：
  - `background`: 由 `rgba($accent, 0.15)` 改為固定深色漸層
  - `border`: 改為 `1px solid rgba(255, 255, 255, 0.22)`
  - `border-radius`: `16px 6px 16px 16px`
  - `padding`: 微調為 `9px 13px`
  - 新增 `box-shadow` 提升對話雲辨識度

- verification:
  - 檢查方式：編輯器 Problems 診斷
  - 結果：`AIStudioChatPanel.vue` 無錯誤（No errors found）

- performance-impact:
  - 無顯著效能影響，僅 CSS 視覺樣式微調

- impact-risk:
  - 低風險
  - 僅影響 AI Studio 左側聊天的使用者訊息視覺，不影響資料與互動邏輯

- regression-test:
  - 進入 `/ai-studio` 發送任意訊息，確認使用者訊息有清楚對話雲
  - 檢查深淺主題下泡泡可讀性
  - 連續發送多條訊息，確認泡泡間距與排列正常

- traceability:
  - user request: 「用戶傳的訊息 要有對話雲阿」

- next-actions:
  - N/A
