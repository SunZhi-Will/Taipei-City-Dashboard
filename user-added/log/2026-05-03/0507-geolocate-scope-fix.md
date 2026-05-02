# 修復 geoLocate 未定義導致地圖頁掛載失敗 / Fix geoLocate ReferenceError in MapContainer mounted hook

## 2026-05-03 05:07

- objective:
  - 修復 `mapStore.js` 中 `geoLocate is not defined` ReferenceError，導致 MapContainer `mounted` hook 拋出例外、地圖頁無法正常載入

- files:
  - Taipei-City-Dashboard-FE/src/store/mapStore.js

- summary:
  - `addGeolocateControl()` 以 `const geoLocate` 宣告 local 變數並加到地圖，但沒有 `return`
  - `initializeMapBox()` 呼叫 `this.addGeolocateControl()` 後試圖在外部作用域使用 `geoLocate.on(...)` → ReferenceError
  - 修正：`addGeolocateControl()` 末尾加 `return geoLocate`；`initializeMapBox()` 改為 `await` 並捕捉回傳值；GA 事件監聽包 `if (geoLocate)` 防護（定位被拒時回傳 undefined）

- change-type:
  - Fixed

- technical-details:
  - `addGeolocateControl` 是 async 函式，permission denied 路徑 `return` 不回傳值（undefined）
  - `initializeMapBox` 改為 `const geoLocate = await this.addGeolocateControl()`
  - GA `.on("geolocate", ...)` 包 `if (geoLocate)` 確保 null-safe

- verification:
  - 瀏覽器開啟 `/mapview?index=food_safety_taipei&city=taipei`
  - Console 不再出現 `ReferenceError: geoLocate is not defined`
  - Vue warn `Unhandled error during execution of mounted hook at <MapContainer>` 消失

- impact-risk:
  - 僅影響 mapStore.js 的地圖初始化流程
  - 定位功能在 permission denied 時靜默跳過，行為與修改前一致
  - GA 事件只在 geoLocate 成功建立時才掛載，無 regression 風險

- regression-test:
  - 開啟地圖頁確認無 console error
  - 允許定位：確認定位按鈕出現且 GA 事件觸發
  - 拒絕定位：確認定位按鈕不出現、console 只有原有 warning 無 ReferenceError

- traceability:
  - N/A

- next-actions:
  - N/A
