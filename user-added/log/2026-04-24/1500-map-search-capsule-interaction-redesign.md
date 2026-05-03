# 地圖搜尋膠囊互動重設 / Map Search Capsule Interaction Redesign

## 2026-04-24 15:00

- objective:
  - 將地圖搜尋改為單一膠囊樣式，並符合「預設僅顯示搜尋按鈕、點擊後由下往上展開輸入欄」的互動需求。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 搜尋預設為快速連結區右側的一顆搜尋 icon 按鈕。
  - 點擊後快速連結 Tag 會上移，搜尋輸入欄從下方向上顯示。
  - 搜尋列改為單層膠囊，提交按鈕改為輸入欄內 icon 按鈕。

- change-type:
  - Changed

- technical-details:
  - 新增 `isSearchExpanded` 狀態，控制搜尋列展開/收合。
  - 新增 `toggleSearchBar()`，切換搜尋列顯示並在收合時清空輸入值。
  - 快速連結區新增 `mapcontainer-quick-locations-search-trigger` 搜尋 trigger 按鈕。
  - 快速連結區加入 `--raised` class，在搜尋展開時上移。
  - 搜尋列改為 `mapcontainer-location-search--open` 轉場顯示（opacity + translateY）。
  - 搜尋送出按鈕改為輸入欄內 icon（`search` / `hourglass_top`）。
  - 搜尋列輸入框改為透明背景、無額外邊框，避免雙層包裝視覺。

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 僅新增少量 UI 狀態切換與 CSS 轉場，無新增 API 請求。
  - 對效能影響低。

- impact-risk:
  - 低風險：變更集中於地圖頁搜尋 UI，未改動地圖定位核心邏輯。
  - 目前搜尋列為 `hide-if-mobile`，手機端仍維持既有行為。

- regression-test:
  - 驗證桌機：預設只顯示搜尋 icon 按鈕。
  - 點擊搜尋按鈕後：Tag 上移、搜尋膠囊由下往上顯示。
  - 於搜尋欄輸入地址或座標後可正常定位。
  - 驗證收合後輸入值會被清空。

- traceability:
  - N/A

- next-actions:
  - P1: 若需要可再加「點擊膠囊外區域自動收合」互動。
