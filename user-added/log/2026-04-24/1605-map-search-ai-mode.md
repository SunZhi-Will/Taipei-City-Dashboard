# 地圖搜尋新增 AI 模式 / Add AI Mode for Map Location Search

## 2026-04-24 16:05

- objective:
  - 在地圖搜尋旁新增 AI 模式，讓使用者可透過 AI 解析地點後進行定位。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 在搜尋按鈕旁新增 `AI` 模式切換按鈕。
  - 開啟 AI 模式後，搜尋會先呼叫 AI 解析地點與座標，再定位地圖。
  - 若 AI 解析失敗，會自動回退到既有地址 geocoding 流程。

- change-type:
  - Added
  - Changed

- technical-details:
  - 新增狀態：
    - `isAISearchMode`（AI 模式開關）
    - `isAIResolving`（AI 解析中）
  - 新增函式：
    - `toggleAISearchMode()`：切換 AI 模式並提示通知。
    - `resolveLocationByAI(input)`：呼叫 `/ai/chat/twai`，要求回傳標準 JSON 座標。
    - `parseAIResolvedLocation(content)`：解析 AI 回覆 JSON，驗證經緯度範圍與數值有效性。
  - 搜尋流程更新：
    - `handleLocationSearch()` 在地標別名比對後，若 AI 模式開啟先走 AI 解析。
    - AI 成功：直接 `flyTo` 定位並顯示 AI 定位通知。
    - AI 失敗：提示後回退到一般 geocoding。
  - UI 更新：
    - 在快速連結區新增 `AI` toggle 按鈕（active 狀態樣式）。
    - 搜尋 icon 按鈕在 `isAIResolving` 時顯示 loading icon。

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 啟用 AI 模式時會多一次 AI API 請求。
  - AI 失敗時會再回退 geocoding，最壞情況增加一次請求延遲。

- impact-risk:
  - 低至中風險：依賴 AI 回應格式與可用性。
  - 已做防呆：JSON 解析失敗或座標無效時不會中斷，會自動回退一般搜尋。

- regression-test:
  - 切換 AI 模式後輸入自然語句地點（如「台北市政府旁邊」）可定位。
  - AI 失敗時顯示「改用一般搜尋」通知並可正常定位。
  - 關閉 AI 模式後行為與既有搜尋一致。

- traceability:
  - N/A

- next-actions:
  - P1: 若需要，可加上 AI 候選地點清單（多結果選擇）提升可控性。
