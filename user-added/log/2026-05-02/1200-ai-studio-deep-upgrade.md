# AI Studio 深度智能升級 / AI Studio Deep Intelligence Upgrade

## 2026-05-02 12:00

- objective:
  - 深度分析 AI Studio 不夠智能的四個根本原因並逐一修正

- files:
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **[Bug Fix] AI 導演稿被 buildComponentNarrative 覆蓋**：AI Studio 的 AI 生成精心策劃的展示敘事，卻被 FE 再跑一次設計給「一般聊天小工具」的 `buildComponentNarrative`。當 AI 回覆被 regex 判斷為 generic 時，整段內容被硬編碼模板取代。修正：`aiStudioChatStore.addQueryData` 改為直接使用 `twaiResult.content`，不再套 `buildComponentNarrative` 包裝。
  - **[Bug Fix] display_plan 投影片找不到對應組件 → 顯示空白**：`componentsFromAgentResult` 最多回傳 primary+3=4 個組件，`selectFocusedComponents` 再依關鍵詞評分砍到 2-4 個。AI 規劃的 8 張投影片各有不同的 `focus_component_id`，但 `componentCards` 只有 4 個，其餘投影片的 canvas 全部顯示空白。修正：新增向量搜尋工具結果的全量補充邏輯（從 `toolTimeline` 解析 raw results，hydrate 後合併），並移除 `selectFocusedComponents` 過濾（改為 `isPrimary` 標記第一個）。
  - **[Improvement] AI 不知道當前場景（多輪修改失效）**：使用者說「把空氣品質改成折線圖」時，AI 收不到「目前有哪些投影片、component_id 是什麼」的資訊，每次都從零開始搜尋，無法做到場景差量修改。修正：`queryByTwai` 接受 `options.sceneContext`，在 AI Studio 模式下將現有圖表類投影片的標題和 component_id 注入到用戶訊息前綴，讓 AI 能做有效的場景編輯。
  - **[Improvement] 向量搜尋結果只用了 40%**：後端最多回傳 10 個組件，但前端只取 agentResult 的 4 個，剩下 6 個直接丟棄。這導致 AI 在 display_plan 中引用到第 5-10 個組件時，FE 找不到對應的 dashboardConfig 而顯示空白。修正：從 `toolTimeline` 取出 `retrieve_components_by_query` 的完整 result，hydrate 所有未包含在 agentResult 的組件後合併。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - **場景注入機制**：`contextualQuestion` 為 IIFE，只在 `options.appMode === 'ai_studio'` 且 `options.sceneContext` 存在、且有圖表類投影片時才啟用前綴注入。fallback 路徑（`includeHistory=false`）不注入以保持最小 context。前綴格式：`[現有展示場景：共N張投影片，圖表類："標題A"(component_id:123)、...]`
  - **組件全量補充**：使用 `[...twaiResult.toolTimeline].reverse().find()` 取最後一次 `retrieve_components_by_query` 的結果，避免多輪搜尋時取到舊結果。以 `Set<String(id)>` 去重後再 `hydrateDashboardComponents`，不重複發 API 請求。
  - **移除 selectFocusedComponents**：AI Studio 不需要語義相關性排序後的截斷，所有 hydrated 組件都保留，以 `.map((item, idx) => ({ ...item, isPrimary: idx === 0 }))` 確保 ChatResultComponents 的 `isPrimary` 欄位存在。
  - **import 清理**：移除 `selectFocusedComponents`（不再使用），加入 `hydrateDashboardComponents`；新增 `import { useAIStudioStore } from './aiStudioStore'`，在 `defineStore` 內部以 `const aiStudioStore = useAIStudioStore()` 取得 scene（Pinia 允許 store 間組合）。

- verification:
  - `get_errors` 工具：aiStudioChatStore.js 與 aiChatService.js 均無錯誤

- impact-risk:
  - **場景注入**：每次 AI Studio 請求 input_tokens 增加約 50-150 tokens（取決於場景投影片數）。可接受，且只在有現有場景時觸發。
  - **移除 selectFocusedComponents**：AI Studio 聊天面板的組件卡片可能顯示更多（最多 10 張），UI 需確認捲動正常。Canvas 多組件情況下 hydrate 成本略增（並行 API）。
  - **buildComponentNarrative 不再呼叫**：若 `twaiResult.content` 為空字串，`finalContent` 會是空字串，chatData 會推入空 content 的 bot 訊息。已有 `!content || !String(content).trim()` 提前返回保護（在 `queryByTwai` 中），所以此情況只會走 fallback 而非返回空內容。

- regression-test:
  - 新對話：輸入「幫我展示臺北空氣品質議題」→ 確認 display_plan 的所有 component slides 都能在 canvas 渲染（不出現空白投影片）
  - 多輪修改：先問議題 → 再說「改成折線圖風格」→ 確認 AI 的回覆中有引用原有組件的 ID
  - 長列表：要求 8 個組件的展示 → 確認 canvas 8 張投影片都有內容而非只有前 4 張

- traceability:
  - 接續 user-added/log/2026-05-02/1056-ai-intelligence-upgrade.md

- next-actions:
  - 建議：`AIStudioView.vue` 的 `watch(lastBotMessage)` 在收到無 `displayPlan` 的回覆時不觸發 `setRightMode('presentation')`，避免純問答回覆也切換視角
