# 修正台北101誤跳淡水 / Fix Taipei 101 Misdirected Search Result

## 2026-04-24 15:15

- objective:
  - 解決搜尋「台北101」時誤跳到淡水等錯誤地點的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 新增 `台北101` 相關地標別名直達座標，避免關鍵字歧義時命中錯誤地址。
  - geocoding 改為取多筆候選（limit=8）後進行評分，避免直接採用第一筆造成偏差。
  - 評分規則加入台北意圖強化與新北市懲罰，降低「台北」查詢落到新北地點的機率。

- change-type:
  - Fixed

- technical-details:
  - `LANDMARK_ALIASES` 新增：`台北101`、`臺北101`、`台北101大樓`、`臺北101大樓`、`101`。
  - 新增 `scoreGeocodeCandidate(feature, input)`：
    - 完整關鍵字命中加分。
    - token 命中加分。
    - POI 類型加分。
    - 若查詢意圖含「台北」，命中 `台北市/臺北市` 大幅加分，命中 `新北市` 扣分。
    - `101` 關鍵字加權。
  - 新增 `pickBestGeocodeResult(features, input)` 選擇最高分候選。
  - geocoding 參數調整：
    - `limit=1` -> `limit=8`
    - 移除 `proximity`，避免地圖中心位置把結果偏向目前附近錯誤地址。

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 每次地址搜尋增加候選評分（最多 8 筆），計算量低，效能影響可忽略。

- impact-risk:
  - 低風險：僅影響地圖搜尋結果挑選邏輯。
  - 已知邊界：若地標別名過短（如 `101`）在部分情境可能過度泛用，後續可再視實際使用頻率調整。

- regression-test:
  - 輸入 `台北101`、`臺北101`、`台北101大樓`，確認定位到信義區101。
  - 輸入 `台北花博公園`、`花博`，確認定位到花博園區。
  - 一般地址查詢與座標輸入仍可正常定位。

- traceability:
  - N/A

- next-actions:
  - P1: 若需要可再加入「先顯示前3筆候選讓使用者點選」模式，完全避免歧義自動選錯。
