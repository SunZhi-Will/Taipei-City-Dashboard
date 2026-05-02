# AI Studio 展示計劃全鏈路整合 / AI Studio Display Plan End-to-End Integration

## 2026-04-24 13:21

- objective:
  - 修正 AI Studio 中 Chat 與輪播/畫布資料流分離問題。
  - 讓後端 AI 回傳可渲染的展示計劃（display_plan），並由前端優先採用。
  - 新增 strict render 行為，避免輪播自動補頁覆蓋 AI 規劃意圖。

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/controllers/ai.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 後端新增 `display_plan` 結構與生成邏輯（mode/style/strict_render/slides/blocks/chart_preference），並在 `/ai/chat/twai` 回應中返回。
  - 前端 `queryByTwai` 新增讀取 `display_plan`，並建立 `resolveSceneFromDisplayPlan()` 將計劃轉成 scene。
  - AI Studio chat store 改為優先採用 display_plan 生成 scene，無 plan 時回退既有 fallback scene。
  - AI Studio 頁面改用 `aiStudioChatStore` 作為監聽來源，修正 chat 與畫布來源不一致。
  - 輪播新增 strict render 支援：有 explicit slides 且 strictRender=true 時，不再自動補缺漏投影片。
  - 輪播新增 `component_explain` 類型投影片顯示，支援「組件說明頁」需求。

- change-type:
  - Added
  - Changed
  - Fixed

- technical-details:
  - BE `AIChatResult` 新增 `DisplayPlan *DisplayPlan`，`ChatWithTWCC` finalize 階段注入 `buildDisplayPlan()`。
  - BE `detectChartPreference()` 依 query 關鍵字回推 bar/line/pie/map/auto，便於前端決定圖形偏好。
  - FE service 新增 `resolveSceneFromDisplayPlan()`，將 snake_case 欄位映射至既有 scene 結構並保留 strictRender。
  - FE `AIStudioView.vue` 將 `useChatStore` 替換為 `useAiStudioChatStore`，避免跨模組資料斷鏈。
  - FE `AIStudioPresentationCanvas.vue` 的 `slides` 計算加入 strict 邏輯，避免 AI 指定順序被自動增補稀釋。

- verification:
  - 透過 `get_errors` 檢查以下檔案均為 `No errors found`：
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/controllers/ai.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- performance-impact:
  - display_plan 為輕量 JSON，回應體積增加有限。
  - strict render 可降低不必要的投影片自動補齊，減少多餘渲染。
  - 目前 display_plan 生成為規則式，計算成本低。

- impact-risk:
  - 中等風險：AI Studio 資料流入口切換到 `aiStudioChatStore`，需留意舊路徑依賴。
  - 若後端 display_plan 欄位格式變更，前端映射需同步更新。
  - display_plan 目前為 v1；複雜場景仍可能回退 fallback scene。

- regression-test:
  - 在 AI Studio 連續提問，確認每輪 bot 回覆可同步驅動畫布與輪播。
  - 提問含「長條圖/折線圖/圓餅圖/地圖」關鍵字，檢查 chart_preference 映射是否合理。
  - 測試 strictRender=true 場景，確認 explicit slides 不被自動補頁。
  - 測試 `component_explain` 投影片顯示與文字回退行為。

- traceability:
  - Related discussion: AI Studio Chat 與輪播流程重構（本次對話）
  - Commit/PR: N/A

- next-actions:
  - P0: 將 display_plan schema 文件化（含版本號與必填欄位），提供 BE/FE 共用契約。
  - P1: 後端新增「AI 原生規劃輸出」模式，逐步取代目前規則式 `buildDisplayPlan()`。
  - P1: 前端加入 display_plan 驗證與 fallback telemetry，觀測無效 plan 比率。
