# 修復 AQI 圖表總合 NaN 顯示 / Fix AQI Chart NaN Summary Display

## 2026-04-24 14:31

- objective:
  - 修正「總合 NaN AQI / 多 / 少」在圖表元件中的顯示問題。
  - 避免 API 回傳值含 `null`、`undefined`、字串數字或非數值時，前端加總與渲染出現 `NaN`。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DistrictChart.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue

- summary:
  - 在 `DistrictChart` 與 `DonutChart` 新增 `toFiniteNumber` 數值正規化函式。
  - 所有加總、序列輸出、最大值計算改用有限數值，非法值統一降為 `0`。
  - 保留既有 UI 與事件流程，不改動 API 契約。

- change-type:
  - Fixed

- technical-details:
  - `DistrictChart.vue`
  - 單序列模式：將 `item.y` 經過 `toFiniteNumber` 後再寫入 `output`、`highest`、`sum`。
  - 多序列模式：累加值由 `+serie.data[i]` 改為 `toFiniteNumber(serie.data[i])`。
  - `highest` 計算改為 `Math.max(...Object.values(output).map(toFiniteNumber))`，避免比較時受非數值污染。
  - `sum` 的 `reduce` 改為對每個值做 `toFiniteNumber`。
  - `DonutChart.vue`
  - `parsedSeries` 生成與 `other` 聚合時，全部以 `toFiniteNumber` 轉換。
  - `sum` 改為以初始值 `0` 的 `reduce` 計算，並對每項做有限數值轉換。

- verification:
  - 以 VS Code 診斷執行檢查：
  - `get_errors` on `DistrictChart.vue` → No errors found
  - `get_errors` on `DonutChart.vue` → No errors found
  - 人工檢視：確認模板中的總合輸出來自修正後的計算結果。

- performance-impact:
  - 新增 `Number()` 與 `Number.isFinite()` 轉換，時間複雜度維持 O(n)。
  - 對現有渲染效能影響可忽略，主要提升穩定性與容錯性。

- impact-risk:
  - 非數值資料將被視為 `0`，可能掩蓋上游資料品質問題。
  - 風險可接受，因為目前優先目標為避免 UI 顯示 `NaN` 造成使用者誤解。

- regression-test:
  - 進入「雙北空氣品質監測站」組件，驗證總合不再顯示 `NaN`。
  - 驗證圖例「多 / 少」顏色與地圖互動（點選行政區過濾）功能未受影響。
  - 用含字串數字與空值的測試資料驗證 Donut 總和顯示。

- traceability:
  - N/A

- next-actions:
  - P1: 檢查後端資料來源是否可保證回傳數值欄位型別，降低前端容錯負擔。
