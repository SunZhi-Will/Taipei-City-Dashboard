# 地圖搜尋模式改為左右切換 / Convert Search Mode to Segmented Toggle

## 2026-04-24 16:08

- objective:
  - 將地圖搜尋中的 AI 模式 UI 調整為左右切換樣式（一般 / AI）。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 將輸入框內單顆 AI 按鈕改為 segmented control。
  - 新增「一般 / AI」雙按鈕，透過左右滑塊表示目前模式。
  - 保持原本搜尋送出、Enter、AI 解析與 fallback 流程。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - 邏輯調整：
    - `toggleAISearchMode()` 改為 `setAISearchMode(enabled)`。
    - 僅在模式真正變更時更新狀態與通知。
  - Template 調整：
    - 新增 `.mapcontainer-location-search-mode` 容器。
    - 新增兩個按鈕：「一般」與「AI」，各自呼叫 `setAISearchMode(false/true)`。
  - Style 調整：
    - `-mode` 使用 grid + `::before` 實作左右滑塊。
    - `.is-ai` 控制滑塊位移到右側。
    - active 狀態文字高亮。

- verification:
  - VS Code 診斷檢查：
    - get_errors on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 無顯著影響（純前端 UI 與事件切換調整）。

- impact-risk:
  - 低風險：模式切換入口改版，底層搜尋流程維持不變。

- regression-test:
  - 在搜尋膠囊內可見「一般 / AI」左右切換。
  - 點選左右項目可切換模式且狀態顯示正確。
  - 兩模式下點搜尋與 Enter 皆可執行。

- traceability:
  - user-added/log/2026-04-24/1606-map-search-ai-button-inside-input.md

- next-actions:
  - N/A
