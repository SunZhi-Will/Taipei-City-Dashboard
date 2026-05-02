# 修正花博公園定位誤配 / Fix Geocoding Mismatch for Taipei Expo Park

## 2026-04-24 15:10

- objective:
  - 解決「台北花博公園」搜尋時誤跳到公園路/中山南路周邊的問題，提升地圖搜尋定位準確度。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 新增地標別名優先命中機制，對「台北花博公園」等關鍵字直接定位到正確座標。
  - 調整 geocoding 參數，加入台北範圍 bbox 與目前地圖中心 proximity，降低錯誤候選被排第一的機率。
  - 保留原本座標輸入解析流程，不影響既有功能。

- change-type:
  - Fixed

- technical-details:
  - 新增 `LANDMARK_ALIASES` 與 `resolveKnownLandmark()`：
    - 支援 `台北花博公園`、`臺北花博公園`、`花博公園`、`圓山花博公園`、`花博`。
    - 命中時直接 flyTo 目標座標 `[121.52173, 25.07059]`。
  - 新增 `normalizeQueryText()`：
    - 做空白移除、臺/台正規化、大小寫一致化。
  - geocoding URL 參數調整：
    - `types=poi,address,place,locality,neighborhood`
    - `bbox=121.3,24.9,121.75,25.3`
    - `proximity=<目前地圖中心>`（若可用）

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。
  - API 候選檢查（排查原因）：
    - 對 `台北花博公園` 查詢時，原 geocoding 第一筆出現公園路地址結果，證實有關鍵字誤配問題。

- performance-impact:
  - 僅增加少量字串比對與常數查表，效能影響可忽略。
  - geocoding 仍維持單次請求，不增加額外 API 次數。

- impact-risk:
  - 低風險：變更集中在搜尋前處理與 geocoding 查詢參數。
  - 已知限制：其他未列入別名的特殊地標，仍仰賴 geocoding 候選品質。

- regression-test:
  - 輸入 `台北花博公園`、`花博公園`、`花博`，確認定位在圓山花博園區。
  - 輸入一般地址（非花博）仍可正常定位。
  - 輸入座標（lng,lat / lat,lng）仍可正常定位。

- traceability:
  - N/A

- next-actions:
  - P1: 可擴充熱門地標 alias 字典（如大巨蛋、101、松菸）。
