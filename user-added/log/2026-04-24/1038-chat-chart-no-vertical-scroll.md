# ChatBot 圖表取消內部上下捲動 / Remove Vertical Scrolling Inside ChatBot Charts

## 2026-04-24 10:38

- objective:
  - 修正 ChatBot 內嵌圖表仍可上下捲動的問題，避免使用者在聊天卡片內出現不必要的內層縱向滾動。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 將聊天內嵌圖表容器從可產生縱向捲動改為禁止縱向 overflow。
  - 保留橫向捲動能力，以因應寬度不足時的圖表內容。
  - 同步關閉 ApexCharts 圖例在聊天卡片內的自動 overflow 行為。

- change-type:
  - Fixed

- technical-details:
  - 原先聊天覆寫使用 `overflow-x: auto` 與 `overflow-y: visible`，在瀏覽器實際計算下可能導致 y 軸仍形成捲動容器。
  - 現改為 `.dashboardcomponent-chart/.dashboardcomponent-loading/.dashboardcomponent-error` 使用 `overflow-y: hidden` 與 `overflow-x: auto`。
  - 補充 `.vue-apexcharts` 的 `overflow: visible`，以及 `.apexcharts-legend` 的 `overflow: visible`、`max-height: none`，避免圖例層形成額外內部 scroll。

- verification:
  - 執行診斷檢查：`get_errors`（目標檔案）結果為 `No errors found`。
  - 人工檢查建議：
    - 在 ChatBot 中查看「扶養比及老化指數」確認卡片內不再可上下捲動。
    - 驗證寬度不足時仍可左右捲動，不會裁切圖表。

- performance-impact:
  - 僅 CSS overflow 行為調整，無額外運算與資料請求。

- impact-risk:
  - 低風險：僅套用於聊天卡片中的圖表預覽。
  - 若未來某些圖型真的需要內部縱向捲動，需再做圖型級別例外處理。

- regression-test:
  - 驗證聊天卡片中含 legend 的圖表不再產生內部上下捲動。
  - 驗證一般 Dashboard 頁面維持原本 scroll 行為。

- traceability:
  - N/A

- next-actions:
  - 若個別圖型仍有特殊捲動行為，可再逐一鎖定該 ApexCharts 元件做專屬覆寫。
