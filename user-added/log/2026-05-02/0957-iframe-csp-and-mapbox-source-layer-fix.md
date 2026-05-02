# 修正 iframe CSP 違規與 Mapbox 3D 建築 source layer 錯誤 / Fix iframe CSP Violation and Mapbox 3D Building Source Layer Error

## 2026-05-02 09:57

- objective:
  - 消除瀏覽器 console 中出現的兩個錯誤：
    1. AI Studio 的 iframe 預設載入 `https://www.gov.taipei/` 觸發 CSP `frame-ancestors` 違規
    2. Mapbox 地圖載入時找不到 source layer `tp_building_height84-18p8j0`，拋出 style validation 錯誤

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/store/mapStore.js

- summary:
  - **AIStudioView.vue**：將 `webUrlInput` 預設值由 `"https://www.gov.taipei/"` 改為 `""`。
    由於 web mode 使用 `v-show`（非 `v-if`），iframe 在頁面初始化時就掛載 DOM，立即以預設 src 發出請求，觸發 `www.gov.taipei` 的 CSP `frame-ancestors` 阻擋。改為空字串後瀏覽器不會發出請求。
  - **mapStore.js**：
    1. 新增 `import.meta.env.VITE_MAPBOXTILE` 存在性檢查，未設定時直接跳過整個 3D 建築初始化流程。
    2. 以 `try/catch` 包裹 `addSource().addLayer()` 呼叫，防止同步拋出異常導致後續初始化中斷。
    3. 新增 `map.on('error', ...)` 監聽器，攔截針對 `taipei_building_3d` / `taipei_building_3d_source` 的 Mapbox event-based validation 錯誤（source layer 驗證錯誤由 Mapbox 內部透過 event 系統觸發，非 throw，try/catch 無法攔截），改為 `console.warn` 輸出，避免 console 出現紅色 Error。

- change-type:
  - Fixed

- technical-details:
  - Mapbox GL JS 的 source layer 驗證發生在 tile worker 回調後，呼叫路徑：`Mo._validateLayer` → `Proxy.fire` → `Pe.fire` → 全域 error event。因此必須透過 `map.on('error', handler)` 捕捉，而非同步 try/catch。
  - CSP `frame-ancestors` 是由目標網站伺服器回應頭設定，前端無法繞過；根本修正是不主動載入受限 URL。
  - `VITE_MAPBOXTILE` guard 同時解決本機開發時未設定 env 變數的情境。

- verification:
  - 修改後重新整理頁面，觀察 console：
    - 不應再出現 `Framing 'https://www.gov.taipei/' violates...` 紅字錯誤
    - 不應再出現 `Error: Source layer "tp_building_height84-18p8j0" does not exist...` 紅字錯誤
    - 若 VITE_MAPBOXTILE 設定正確且 tileset 正常，3D 建築應正常顯示
    - 若 tileset 中 source layer 名稱不符，僅輸出 `console.warn` 黃色警告

- impact-risk:
  - **AIStudioView**：`webUrlInput` 預設為空字串，web mode 的 iframe 初始狀態為空白（功能本身即為 WIP，toolbar 尚無 web 模式切換按鈕），影響極低。
  - **mapStore**：若 `VITE_MAPBOXTILE` 未設定或 tileset 無效，3D 建築圖層靜默跳過，地圖其餘功能不受影響。

- regression-test:
  - 開啟 AI Studio，確認頁面 console 無 CSP 相關紅字
  - 開啟地圖頁面（桌面裝置），確認 3D 建築圖層正常（若 VITE_MAPBOXTILE 已設定）
  - 清空 VITE_MAPBOXTILE 後重啟，確認地圖仍可正常初始化

- traceability:
  - N/A

- next-actions:
  - 確認 `VITE_MAPBOXTILE` 所指向的 Mapbox tileset 是否仍有效，若 source layer 名稱已更名需同步更新 `mapConfig.js` 中的 `"source-layer"` 值
  - AI Studio web mode 若需正式啟用，應在 toolbar 新增切換按鈕，並提供 URL 輸入欄位
