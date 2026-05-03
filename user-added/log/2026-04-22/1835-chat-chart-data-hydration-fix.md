# 修正聊天圖表資料補齊流程 / Fix Chat Chart Data Hydration Flow

## 2026-04-22 18:35

- objective:
  - 修正聊天中已選到組件但原生圖表仍無法顯示的問題。
  - 讓聊天的組件資料補齊流程與正式頁面一致，取得可渲染的 chart_data。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 新增聊天專用的完整組件 hydration 流程，先抓 `/component/:id/all`，再抓 `/component/:id/chart`。
  - 依 time_from/time_to 自動補上 chart API 所需時間參數，並同步寫回 chart_data 與 chart_config.categories。
  - 將向量搜尋與 agent_result 兩條聊天組件路徑統一改用同一個完整 hydration helper，避免只有 metadata、沒有圖表資料。

- change-type:
  - Fixed

- technical-details:
  - 在 chatStore 中新增 `buildChartParams` 與 `fetchCompleteDashboardConfig`。
  - `fetchCompleteDashboardConfig` 會比照 EmbedView 與 contentStore 的流程，對選定 city 的組件再追加 `/chart` 呼叫。
  - `hydrateDashboardComponents` 與 `ensureDashboardConfigs` 已改成共用完整 hydration，確保聊天主圖表可直接渲染。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/store/chatStore.js，結果為 No errors found。
  - 以搜尋確認新 helper 已接到兩條聊天組件路徑：`hydrateDashboardComponents` 與 `ensureDashboardConfigs`。

- performance-impact:
  - 每個聊天主組件會額外多一次 chart API 呼叫，會增加少量等待時間。
  - 目前只對聊天中實際要顯示的少數組件做 hydration，影響範圍受限。

- impact-risk:
  - 若 chart API 回傳失敗，會寫入空陣列避免前端崩潰，但圖表仍可能顯示空資料。
  - 若某些組件 time_from 配置特殊且不符合既有規則，可能仍需個別檢查該組件 API 響應。

- regression-test:
  - 測試聊天查詢明確指標，例如「扶養比及老化指數」，確認聊天主卡會載入實際圖表。
  - 測試同一組件在 EmbedView 與聊天中的顯示是否一致。
  - 測試 chart API 失敗情況，確認聊天不會因缺資料而整段崩潰。

- traceability:
  - Related log: user-added/log/2026-04-22/1827-chat-ai-summary-and-chart-rendering.md
  - Related implementation: Taipei-City-Dashboard-FE/src/views/EmbedView.vue

- next-actions:
  - 以實際聊天查詢驗證 chart API 是否對所有候選組件都能正確回傳資料；若仍有空白圖表，再針對該組件的 API 響應做個案檢查。