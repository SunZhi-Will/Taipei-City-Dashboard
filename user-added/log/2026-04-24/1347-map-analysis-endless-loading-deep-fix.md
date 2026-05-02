# 地圖分析面板無限轉圈深度修復 / Deep Fix for Endless Loading in Map Analysis Panel

## 2026-04-24 13:47

- objective:
  - 針對「互動分析面板仍持續轉圈」進行根因級排查與防呆修復，確保任何 API 異常都不會卡在 loading。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
- summary:
  - 新增資料載入流程的多層容錯：主路徑 axios + fallback fetch 路徑（`/api/dev`、`/api`、`/api/v1`）。
  - 新增 payload 格式檢查，避免 API 回傳 HTML/非 JSON 時仍被當成功而導致後續異常。
  - 新增 `finally` 強制收斂 loading，確保任何錯誤分支都會結束轉圈。
  - 補強 city 參數來源，避免組件缺 city 時查詢失敗。
- change-type:
  - Fixed
- technical-details:
  - 新增 `cloneComponent()`：降低 clone 失敗導致中斷的風險。
  - `hydrateAnalysisComponent()` 改為：
    - 主 API 呼叫加 `timeout: 12000`。
    - 主 API 失敗或 payload 非 object 時，依序嘗試 fallback routes。
    - 檢查 payload 結構，若 `data` 非 array，改以空資料渲染並提示錯誤訊息。
    - 使用 `finally` 統一 `resolvedComponent` 與 `panelLoading=false`，避免卡圈。
  - `getChartParams()` 補上 city fallback：`component.city || component.map_config[0].city || 'taipei'`。
- verification:
  - diagnostics：`MapAnalysisPanel.vue` -> No errors found。
  - API 實測：
    - `GET /api/dev/component/217/chart?city=taipei` -> 200
    - `GET /api/dev/component/217/chart?city=metrotaipei` -> 200
    - `GET /api/dev/component/213/chart?city=metrotaipei` -> 200
  - 組件資料確認：`bike_map(217)` 於 dashboard API 中有 chart_config/map_config，但初始無 chart_data，符合面板需補抓資料的設計。
- performance-impact:
  - 只在開啟分析面板且缺 chart_data 時才觸發補抓，平時零額外成本。
  - fallback 路徑僅主路徑異常時觸發，正常情況不增加負擔。
- impact-risk:
  - 低風險：範圍限定於分析面板資料水合流程。
  - 若後端瞬斷，面板會顯示錯誤提示與空資料，不會卡住交互。
- regression-test:
  - 驗證自行車道路網圖資、道路統計、YouBike 使用情況三種組件皆可打開分析面板。
  - 驗證關閉面板後地圖篩選可清除。
  - 驗證 API 失敗時面板不再無限轉圈。
- traceability:
  - N/A
- next-actions:
  - 可加入一個右上「重試載入」按鈕，讓使用者遇到短暫 API 失敗可一鍵重試（P1）。
