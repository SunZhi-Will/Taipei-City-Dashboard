# Agent 結果聚焦與原生元件補齊 / Agent Result Focusing And Native Component Hydration

## 2026-04-22 15:58

- objective:
  - 修正 Agent + RAG 回答時顯示過多候選組件，且落回 generic 卡片而非原生 DashboardComponent 的問題。
  - 讓使用者查詢具明確目標（如「扶養比及老化指數」）時，優先聚焦單一最相關組件。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 新增「意圖判定 + 排名分數」流程，對檢索結果做聚焦。
  - 查詢具直接組件意圖時，若第一名優勢明顯，僅回傳 top 1；否則回傳 top 3。
  - 無論結果來源（/ai/components/search 或 /components/search 或 /vector/component），都會先嘗試補齊 dashboardConfig，能渲染原生 DashboardComponent 才顯示原生。

- change-type:
  - Fixed

- technical-details:
  - 新增函式：
    - normalizeText
    - isDirectComponentIntent
    - computeComponentMatchScore
    - selectFocusedComponents
    - ensureDashboardConfigs
  - 流程調整：
    - 取得結果後，先做 dashboardConfig hydration（透過 /component/:id/all）
    - 再做聚焦排序，減少一次塞太多候選

- verification:
  - get_errors 檢查：
    - Taipei-City-Dashboard-FE/src/store/chatStore.js -> No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - hydration 請求數量與候選結果數成正比；聚焦後實際顯示數降低，整體 UI 負擔下降。

- impact-risk:
  - 中低風險：分數策略可能在少數模糊查詢選錯主結果。
  - 緩解：若分差不明顯仍保留 top 3，不強制只顯示一筆。

- regression-test:
  - [ ] 查詢「扶養比及老化指數」應優先顯示單一主組件且為原生 DashboardComponent
  - [ ] 查詢模糊主題（如「高齡」）應顯示最多 3 筆候選
  - [ ] 若 detail hydration 失敗，仍可 fallback 顯示不致中斷

- traceability:
  - related-log: user-added/log/2026-04-22/1553-聊天結果還原原生元件顯示-chat-result-native-component-rendering.md

- next-actions:
  - 建議後端新增批次 detail 端點，降低前端逐筆 hydration 成本。
