# 修正地標定位提示文字錯誤 / Fix Landmark Search Toast Label Mismatch

## 2026-04-24 15:17

- objective:
  - 修正查詢地標時通知文字固定顯示「花博公園」的錯誤，避免地圖定位正確但提示名稱錯誤。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 將地標命中回傳值從單純座標改為包含命中 alias 與座標。
  - 通知文字改為使用實際命中 alias 顯示，避免寫死為花博公園。

- change-type:
  - Fixed

- technical-details:
  - `resolveKnownLandmark()`：
    - 原本回傳 `[lng, lat]`
    - 改為回傳 `{ alias, coordinates }`
  - `handleLocationSearch()`：
    - 地標命中時改用 `knownLandmarkMatch.alias` 產生通知文字。
    - flyTo 仍使用相同座標流程，不影響實際定位。

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 僅增加輕量物件回傳，效能影響可忽略。

- impact-risk:
  - 低風險：僅調整提示文案來源，不改 geocoding 與 flyTo 行為。

- regression-test:
  - 輸入 `台北101`，確認提示顯示為 `已定位到 台北101`（或對應 alias）。
  - 輸入 `花博公園`，提示顯示為對應花博 alias。
  - 地圖定位行為維持正確。

- traceability:
  - N/A

- next-actions:
  - P1: 若需要，可將 alias 再映射為統一顯示名稱（例如 `台北101`、`台北花博公園`），避免顯示過短別名如 `101`。
