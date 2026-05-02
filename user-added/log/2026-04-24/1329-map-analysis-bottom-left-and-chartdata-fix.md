# 地圖分析面板左下角與轉圈修正 / Move Map Analysis Panel to Bottom-Left and Fix Endless Loading

## 2026-04-24 13:29

- objective:
  - 將地圖互動分析面板移動到左下角，避免占用過大主要視區。
  - 修正分析面板組件持續轉圈（chart_data 缺失導致無限 loading）問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue
- summary:
  - 分析面板位置由右上大型浮層調整為左下角較小浮層（更符合地圖操作視角）。
  - 新增分析面板內「按需讀取 chart_data」機制：若 component 尚未帶 chart_data，會自動呼叫 `/component/{id}/chart` 補齊。
  - 新增載入中與錯誤提示 UI，避免使用者看到持續轉圈卻無回饋。
  - 關閉面板時改以已解析元件清除地圖篩選，確保清除目標一致。
- change-type:
  - Fixed
- technical-details:
  - 在 `MapAnalysisPanel.vue` 新增：
    - `resolvedComponent`、`panelLoading`、`panelError` 狀態。
    - `hydrateAnalysisComponent()`：當 `chart_data` 不存在時，依 component 的 `city` 與時間範圍參數（透過 `getComponentDataTimeframe`）呼叫 chart API 取得資料。
    - `watch(props.component, { immediate: true })`：每次切換分析目標即重建資料。
  - 樣式調整：
    - 位置改為 `left: 12px; bottom: 12px;`
    - 尺寸改為 `width: min(340px, 30vw); height: min(360px, 42vh);`
    - 新增 loading spinner 與錯誤訊息區塊。
- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/components/map/MapAnalysisPanel.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/views/MapView.vue -> No errors found
  - 需於瀏覽器實測：
    - 點擊地圖左欄 component 的「分析」後，面板應在左下角出現。
    - 面板不應無限轉圈；若 API 失敗，應出現錯誤提示文字。
- performance-impact:
  - 僅在使用者打開分析面板時才補抓 chart_data，平時無額外請求。
  - 可能新增一次 chart API 呼叫，但可避免空轉與重複操作成本。
- impact-risk:
  - 低風險：變更範圍僅 MapAnalysisPanel。
  - 若後端 chart API 短暫失敗，會顯示錯誤提示並以空資料渲染，不會卡住互動流程。
- regression-test:
  - 驗證地圖頁左欄展開、圖層勾選、儀表板切換功能維持正常。
  - 驗證分析面板可正常打開、關閉、套用與清除篩選。
  - 驗證 `air_station_map_metrotaipei` 與自行車道路網相關 component 可正常顯示內容。
- traceability:
  - N/A
- next-actions:
  - 若你希望左下角再更貼邊或更小，可再加「收合為 icon」模式（P1）。
