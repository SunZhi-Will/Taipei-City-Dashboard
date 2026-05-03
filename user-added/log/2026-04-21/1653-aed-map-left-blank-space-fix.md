# AED 左側空白版面修正 / Fix AED Left Blank Layout Space

## 2026-04-21 16:53

- objective:
  - 修正地圖頁中 AED 主題左側出現大片空白的視覺問題，保留現有控制卡片操作能力。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 新增 `isAedDashboard` 判斷，當儀表板 index 包含 `aed` 時啟用覆蓋式左欄版型。
  - 將 AED 主題左欄（`.map-charts` / `.map-charts-nodashboard`）改為絕對定位覆蓋在地圖上，避免固定雙欄導致左側空白區塊。
  - 維持左欄寬度、滾動與既有互動（toggle、info、filter）不變，僅調整版面呈現策略。

- change-type:
  - Fixed

- technical-details:
  - 在 `MapView.vue` 新增 computed: `isAedDashboard`。
  - template 根容器改為動態 class，於 AED 主題套用 `map-overlay-panel`。
  - `.map` 增加 `position: relative;` 作為覆蓋定位參考。
  - 新增 `.map-overlay-panel` scoped 規則，將左欄設為 `position: absolute; top: 0; left: 0; z-index: 2;`。

- verification:
  - 已執行語法與型別檢查：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/MapView.vue`，結果為 `No errors found`。
  - 已確認變更檔案成功寫入並符合 Vue SFC 語法。

- performance-impact:
  - 無資料計算路徑變更，僅樣式與容器 class 判斷，效能影響可忽略。
  - 可能改善使用者感知：地圖視區可用寬度增加，不再被固定左欄壓縮。

- impact-risk:
  - 風險：AED 主題左欄改為覆蓋式後，地圖左上角部份區域會被卡片遮擋。
  - 緩解：僅針對 `index` 包含 `aed` 主題生效，其他主題仍維持原雙欄版型。

- regression-test:
  - 驗證 AED 主題地圖頁：左側不再出現大片空白，卡片可正常操作。
  - 驗證非 AED 主題地圖頁：版面仍維持原本雙欄行為。
  - 驗證手機版（`hide-if-mobile` 路徑）與桌面版切換無樣式錯位。

- traceability:
  - N/A

- next-actions:
  - 建議在實機確認 AED 主題於不同解析度（1366x768、1920x1080）下卡片覆蓋比例是否需要再微調。
