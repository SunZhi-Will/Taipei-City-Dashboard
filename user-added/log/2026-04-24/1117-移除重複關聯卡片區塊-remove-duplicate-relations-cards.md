# 移除重複關聯卡片區塊 / Remove Duplicate Relations Card Block

## 2026-04-24 11:17

- objective:
  - 移除聊天視窗中重複渲染的關聯卡片區塊，避免與既有指標/組件展示重複。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
- summary:
  - 刪除 bot 訊息內以 `chat.relations` 生成的 `.dashboard-cards-area` 區塊。
  - 移除對應的 `.dashboard-cards-area` / `.dashboard-card` scoped SCSS，避免保留無用樣式。
  - 保留 `chat.relations` 資料傳遞給按鈕行為（例如建立儀表板）以維持既有功能。
- change-type:
  - Fixed
- technical-details:
  - 模板層移除 `v-if="chat.relations && chat.relations.length > 0"` 的卡片迴圈渲染區。
  - 樣式層移除卡片網格與 hover 高亮效果，避免在訊息流中產生第二套資訊展示。
  - 不調整 `qaBtnHandler(btn.text, chat.relations)` 以確保功能參數仍完整。
- verification:
  - 執行檔案診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue`，結果為 `No errors found`。
  - 文字搜尋來源確認：`dashboard-cards-area` 來源位於 `ChatBox.vue`，已刪除該模板區塊。
- performance-impact:
  - 減少一段 DOM 渲染與樣式計算，對聊天訊息渲染成本有小幅下降。
- impact-risk:
  - 若使用者依賴該舊卡片視覺提示，UI 上會改為只看主要組件結果區塊。
  - 功能風險低，因關聯資料仍保留於按鈕流程。
- regression-test:
  - 驗證聊天回覆含 relations 時，不再出現重複卡片。
  - 驗證聊天回覆含 components 時，`ChatResultComponents` 仍正常顯示。
  - 驗證「建立儀表板」按鈕可正常建立，無 relations 參數遺失。
- traceability:
  - N/A
- next-actions:
  - 如需，將 `AIStudioChatPanel.vue` 中現行 relations 呈現策略與 `ChatBox.vue` 做一致化規範盤點（P2）。
