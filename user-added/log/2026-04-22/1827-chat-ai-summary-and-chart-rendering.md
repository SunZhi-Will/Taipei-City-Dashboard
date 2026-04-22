# 聊天改為 AI 統整回答並顯示原生圖表 / Chat Uses AI-Synthesized Answer and Native Chart Rendering

## 2026-04-22 18:27

- objective:
  - 修正聊天結果未顯示實際圖表，只顯示預覽與檢索中繼資訊的問題。
  - 將使用者可見輸出改成 AI 最終統整答案，隱藏 RAG、分數、主次候選、索引等工程語彙。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 移除聊天訊息中的 answer mode 標籤與 fallback 卡片中的相關性/排名資訊。
  - 將聊天主組件卡由 preview 模式改為 focus 模式，直接渲染原生圖表內容。
  - 新增前端最終答案統整邏輯，當已有組件結果時，改以使用者語氣整合成可讀回答，避免暴露檢索流程細節。
  - 更新 TWAI system prompt，要求模型先檢索再統整，且不得輸出 RAG、score、index、id、候選排序等中繼資訊。

- change-type:
  - Fixed

- technical-details:
  - ChatResultComponents 重新分為 primary 與 secondary 顯示結構，primary 走 DashboardComponent focus 模式，secondary 改為簡潔延伸卡片。
  - chatStore 新增 buildComponentNarrative 與 summarizeRelatedComponents，將 AI 原始回覆與實際檢索到的組件資訊合併成最終面向使用者的說明。
  - buildTwaiMessages 的 system prompt 改寫為產品導向回覆約束，強化先查詢組件再回覆的要求。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue，結果為 No errors found。
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/store/chatStore.js，結果為 No errors found。
  - 使用搜尋檢查聊天元件是否仍殘留「主結果 / 符合程度 / 相關性 / 智慧推薦 / 智慧回覆」等詞，結果為 No matches found。

- performance-impact:
  - 新增的文字統整為常數時間字串組裝，對前端效能影響可忽略。
  - focus 模式直接顯示原生圖表，會比 preview 模式多出實際圖表渲染成本，但只在聊天主結果區顯示一個主圖表，避免大幅擴張負載。

- impact-risk:
  - 若某些組件缺少 dashboardConfig，仍會退回簡潔文字卡，不會造成畫面中斷。
  - 若模型仍未觸發 tool call，前端會以 direct intent fallback 補抓組件，但回答品質仍部分依賴向量檢索結果品質。

- regression-test:
  - 測試直接詢問明確指標，例如「扶養比及老化指數」，確認聊天區會先顯示 AI 說明，再顯示原生圖表。
  - 測試一般對話問題，確認未帶組件時仍只顯示自然語言回答，不出現檢索術語。
  - 測試向量 fallback 路徑，確認卡片不再顯示排名與相關性分數。

- traceability:
  - Related logs: user-added/log/2026-04-22/1607-agentic-primary-related-rendering.md
  - Related logs: user-added/log/2026-04-22/1642-agent-result-contract-full-implementation.md

- next-actions:
  - 觀察 TWAI 在 force_tool_call 與一般問題下的實際 tool call 成功率，必要時再補後端強制檢索策略。