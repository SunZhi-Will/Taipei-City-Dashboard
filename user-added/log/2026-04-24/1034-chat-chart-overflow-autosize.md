# ChatBot 內嵌圖表超出範圍修正 / Fix ChatBot Embedded Chart Overflow and Auto Height

## 2026-04-24 10:34

- objective:
  - 修正 ChatBot 中內嵌 Dashboard 圖表超出容器範圍問題，並讓高度可隨內容自適應。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 僅在聊天元件內對 `DashboardComponent` 進行樣式覆寫，不影響一般儀表板頁面。
  - 移除聊天內嵌圖表容器固定高度/最大高度限制，改為自動高度。
  - 圖表容器在寬度不足時改為可橫向捲動，避免內容外溢切出卡片。

- change-type:
  - Fixed

- technical-details:
  - 於 `ChatResultComponents.vue` 新增 `:deep` 覆寫：
  - `.dashboardcomponent` 設為 `height: auto`、`max-height: none`。
  - `.dashboardcomponent-chart/.dashboardcomponent-loading/.dashboardcomponent-error` 設為 `height: auto`、`max-height: none`，並調整 `overflow` 為 `overflow-x: auto`、`overflow-y: visible`。
  - 補強 ApexCharts 包裹層 `.vue-apexcharts` 與 `.apexcharts-canvas/.apexcharts-svg` 的寬度限制，避免在聊天卡片中超寬外溢。

- verification:
  - 執行診斷檢查：`get_errors`（目標檔案）結果為 `No errors found`。
  - 人工檢查建議：
    - 在 ChatBot 中開啟「長照ABC 行政區統計」確認圖表不再超出卡片。
    - 確認圖表高度會依內容增加，不再被固定容器裁切。
    - 確認一般儀表板頁面（非 ChatBot）顯示未受影響。

- performance-impact:
  - 僅樣式層調整，無新增計算邏輯與網路請求。
  - 預期效能影響可忽略。

- impact-risk:
  - 低風險：作用範圍限定在 `ChatResultComponents` 內嵌內容。
  - 邊界情況：極寬圖表將顯示橫向捲動而非溢位。

- regression-test:
  - 測試 ChatBot 與 AI Studio 兩處聊天面板中嵌入圖表顯示。
  - 測試非聊天場景的 Dashboard 元件高度與排版維持原行為。

- traceability:
  - N/A

- next-actions:
  - 若仍有單一圖型在特定資料量下過高，可再針對該圖型元件（如 BarChart）加入聊天模式專屬 `height` 參數。
