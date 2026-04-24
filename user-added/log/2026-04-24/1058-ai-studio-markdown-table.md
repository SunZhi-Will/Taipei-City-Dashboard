# AI Studio 聊天 Markdown 表格渲染修正 / Fix Markdown Table Rendering in AI Studio Chat

## 2026-04-24 10:58

- objective:
  - AI Studio 聊天機器人回傳含 Markdown 表格語法的內容時，UI 顯示原始符號（`| 排名 | ...`），而非美觀的表格，使用者體驗不佳。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
  - Taipei-City-Dashboard-FE/package.json

- summary:
  - 安裝 `marked`（Markdown → HTML 解析）與 `dompurify`（XSS 淨化）套件。
  - 在 `<script setup>` 新增 `renderMarkdown()` 函式，將 bot 訊息內容解析為安全 HTML。
  - 將 template 中 bot 文字由 `<p>{{ chat.content }}</p>` 改為 `<div v-html="renderMarkdown(chat.content)" />`，並加上 `acp__bot-markdown` class。
  - 在 SCSS 新增 `&__bot-markdown` 樣式區塊，涵蓋 `table`、`th/td`、奇偶列底色、hover 效果、`code` 行內樣式。

- change-type:
  - Fixed

- technical-details:
  - `marked.setOptions({ breaks: true })` 讓單行換行也能正確斷行。
  - `DOMPurify.sanitize()` 移除任何可能的 XSS 向量（script、onerror 等），確保 OWASP A03 合規。
  - `white-space: normal` 覆寫原本的 `pre-wrap`，讓 HTML 表格可正常流排。
  - 表格使用 `border-collapse: collapse` + `overflow: hidden` + `border-radius: 6px` 達成圓角效果。

- verification:
  - 執行 `npm install` 確認套件安裝成功（marked 3 packages added）。
  - 在 AI Studio 輸入「交通壅塞」後，bot 回覆的 Markdown 表格應顯示為帶底色、hover 效果的 HTML 表格。
  - 確認純文字訊息仍正常顯示（`<p>` 包裝由 marked 自動處理）。
  - ESLint 需要 `<!-- eslint-disable-next-line vue/no-v-html -->` 已加入以抑制 lint 警告。

- performance-impact:
  - `marked.parse()` 為同步操作，訊息數量通常 <50 則，效能影響可忽略。
  - DOMPurify 首次呼叫會建立 DOM 沙箱，後續呼叫快取複用。

- impact-risk:
  - 低風險：僅影響 bot 訊息的顯示方式，user bubble 與其他功能不受影響。
  - DOMPurify 防止 XSS，bot 回傳惡意 HTML 亦安全。

- regression-test:
  - [ ] 輸入含 Markdown 表格的查詢（如「交通壅塞」），確認表格正確渲染。
  - [ ] 輸入純文字查詢，確認正常顯示無多餘標籤。
  - [ ] 確認「建立儀表板」按鈕功能正常。
  - [ ] 確認 ChatResultComponents 組件卡片正常顯示。

- traceability:
  - N/A

- next-actions:
  - 可考慮將 `renderMarkdown` 提取為共用 composable，供其他聊天元件（如 DialogChatMessage）複用。
  - 優先級：低（目前僅 AIStudioChatPanel 有此需求）。
