# 修正搜尋 Enter 無法觸發 / Fix Enter Key Not Triggering Search

## 2026-04-24 15:20

- objective:
  - 修正地圖搜尋輸入欄按下 Enter 時，未直接觸發查詢的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 將搜尋膠囊由一般容器改為 `form`，統一由 `submit` 事件處理查詢。
  - 按鈕改為 `type="submit"`，讓點擊按鈕與按 Enter 共用同一條執行路徑。
  - 移除按鈕上的 click 綁定，避免 submit + click 造成重複觸發。

- change-type:
  - Fixed

- technical-details:
  - 搜尋區塊：`div` -> `form`。
  - 新增 `@submit.prevent="handleLocationSearch"`。
  - 移除 input 上 `@keydown.enter.prevent`，改由標準 form submit 接管 Enter 行為。
  - 搜尋按鈕：`type="button"` -> `type="submit"`。

- verification:
  - VS Code 診斷檢查：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 無顯著效能影響，僅事件觸發方式調整。

- impact-risk:
  - 低風險：僅調整搜尋 UI 的事件綁定方式，不變更地圖定位邏輯。

- regression-test:
  - 展開搜尋膠囊後，輸入地址按 Enter 應直接觸發查詢。
  - 點擊搜尋 icon 按鈕仍可正常查詢。
  - 定位成功/失敗通知流程維持正常。

- traceability:
  - N/A

- next-actions:
  - P1: 若使用者常用中文輸入法，可再補 `composition` 狀態判斷，以避免組字階段誤觸 submit。
