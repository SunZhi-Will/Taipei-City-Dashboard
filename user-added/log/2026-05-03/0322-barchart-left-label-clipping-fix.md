# 橫向長條圖左側標籤裁切修正 / Bar Chart Left Label Clipping Fix

## 2026-05-03 03:22

- objective:
  - 修正從圓餅圖切換至橫向長條圖後，左側 y 軸標籤被裁切的問題。
  - 提升食安 dashboard 中 BarChart 切換後的可讀性與穩定度。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarChart.vue

- summary:
  - 擴大 BarChart 左側繪圖留白，讓長條圖類別文字不再貼邊或被切掉。
  - 加入 ApexCharts 的 parent/window resize redraw 設定，提升切換後重算版面的穩定性。
  - 調整 y 軸標籤寬度與 offset，避免標籤被擠出可視區域。

- change-type:
  - Fixed

- technical-details:
  - `chart` 設定新增：
    - `redrawOnParentResize: true`
    - `redrawOnWindowResize: true`
    - `parentHeightOffset: 0`
    - `offsetX: 6`
  - `grid.padding.left` 由 `0` 調整為 `24`。
  - `yaxis.labels` 調整：
    - `minWidth: 72`
    - `maxWidth: 96`
    - `offsetX: 0`
  - 保留既有文字截斷 formatter，避免超長標籤破壞整體版面。

- verification:
  - VS Code 診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/dashboardComponent/components/BarChart.vue`，結果 `No errors found`。
  - 靜態檢查：確認修正集中於 BarChart，不影響 DonutChart 與其他圖型。

- performance-impact:
  - 僅在圖表尺寸變更時增加 redraw，成本低且只在切換/resize 觸發。
  - 額外左邊距對渲染成本無顯著影響。

- impact-risk:
  - 左側留白增加後，極窄寬度下實際 bar 區域會稍微縮小。
  - 若其他 BarChart 場景有超長分類名稱，可能仍需個別調整 formatter 或寬度策略。

- regression-test:
  - 在 `致病原因分布` 由 `圓餅圖` 切換到 `橫向長條圖`，確認左側文字不再被切到。
  - 驗證其他使用 `BarChart` 的元件（如 `食品中毒攝食場所`）標籤仍正常對齊。
  - 驗證桌機與較窄視窗下切換都能維持可讀性。

- traceability:
  - Related request: 使用者回報「圓餅圖切換橫向長條圖，大小沒更新，導致文字左邊被切到」。

- next-actions:
  - 若仍有個別圖表在極窄寬度下擠壓，可再加入依容器寬度動態調整 `maxWidth` 的策略。
