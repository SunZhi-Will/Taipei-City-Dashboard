# 地圖分析面板支援城市切換 / Enable City Switch in Map Analysis Panel

## 2026-05-03 05:18

- objective:
  - 修正地圖分析面板中的組件卡片，讓使用者可像儀表板圖表一樣切換城市，避免固定顯示單一城市資料。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
- summary:
  - 在地圖分析面板中啟用城市下拉選單與城市標籤顯示。
  - 實作 `@change-city` 事件，切換到同 index 的另一城市組件，並重新 hydrate 圖表資料。
  - 切換城市前先清除既有 map filter，避免上一城市篩選殘留影響結果。
  - 將 map toggle 從 disabled 改為可互動狀態，避免 UI 呈現鎖定感。
- change-type:
  - Fixed
- technical-details:
  - 新增 `useContentStore`，使用 `cityDashboard.components` 依 `index + city` 尋找可切換組件。
  - 新增 `panelCityTag`、`panelSelectList`、`panelSelectDisabled` 三個 computed，動態決定城市標籤與下拉內容。
  - 新增 `handleChangeCity(city)`：清理 map filter 後，呼叫 `hydrateAnalysisComponent(selectedData)` 完成資料切換。
  - `DashboardComponent` props 調整：`select-btn=false -> true`，新增 `select-btn-list`、`select-btn-disabled`，`city-tag=[]` 改為城市標籤資料。
- verification:
  - 以診斷工具檢查檔案錯誤：`get_errors(MapAnalysisPanel.vue)`，結果為 No errors found。
  - 人工程式碼檢查：確認模板已綁定 `@change-city="handleChangeCity"`，且 `select-btn`/`select-btn-list`/`city-tag` 已傳入。
- performance-impact:
  - 僅在使用者切換城市時觸發一次資料重載，平時無額外輪詢或背景負擔。
  - 運算主要為小量陣列過濾（同 index 組件），對整體效能影響可忽略。
- impact-risk:
  - 若 `cityDashboard.components` 未包含對應城市，將維持現狀不切換；不會導致崩潰。
  - 切換時清除 map filter 可能改變使用者當前分析狀態，屬預期行為以避免跨城市污染。
- regression-test:
  - 在 `/mapview` 開啟分析面板，確認城市下拉可見且可切換。
  - 切換 `metrotaipei -> taipei` 後，確認圖表與城市 tag 同步更新。
  - 切換城市後點擊圖表篩選，確認 map filter 仍可正確套用與清除。
- traceability:
  - N/A
- next-actions:
  - 建議補一個元件測試或 E2E：驗證 `handleChangeCity` 在無對應城市資料時不拋錯。
