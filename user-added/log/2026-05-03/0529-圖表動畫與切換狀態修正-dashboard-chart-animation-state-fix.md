# 圖表動畫與切換狀態修正 / Fix Chart Animation and Toggle State

## 2026-05-03 05:29

- objective:
  - 修正圖表在切換後動畫瞬間完成的體感問題。
  - 修正切換地圖/圖表或重繪後，圖表型別回到預設值造成視覺不一致的問題。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 在 DashboardComponent 新增 chart render key，於圖表型別變更時遞增，確保圖表實例在切換後重建，避免動畫被快轉體感。
  - 新增 initialChartType 同步監聽，讓父層記錄的圖表型別可正確回灌，避免切換地圖/返回後掉回預設圖表。
  - 在 DashboardView 將 componentActiveCharts 實際傳入 initial-chart-type，打通「紀錄」與「回灌」流程。
  - 調整 AnimatedColumnChart 的動畫設定與播放間隔：改為依組件 _animate.interval_ms（含下限）控制，並同步調整 Apex 動畫速度與 gradual 動畫，讓每步月份切換更平滑。

- change-type:
  - Fixed

- technical-details:
  - DashboardComponent:
    - 新增 `chartRenderKey`。
    - `watch(activeChart)` 內遞增 key，並保留既有 `chartTypeChange` event。
    - 新增 `watch(() => props.initialChartType)`，當父層型別更新時同步到內部 `activeChart`。
    - 動態圖表 `:key` 改為含 `chartRenderKey`，提升切換時動畫一致性。
  - DashboardView:
    - 三個 `DashboardComponent` 使用點（focus/half/default）皆加上 `:initial-chart-type="componentActiveCharts[...]"`。
  - AnimatedColumnChart:
    - 新增 `animIntervalMs` computed，讀取 `map_config[0].property` 的 `_animate.interval_ms`，並設最小值 900ms。
    - Apex 動畫 `speed`、`dynamicAnimation.speed` 改為跟隨 `animIntervalMs`。
    - 啟用 `animateGradually`，避免更新呈現瞬跳。
    - 播放 timer 由固定 `1500ms` 改為 `animIntervalMs`。

- verification:
  - 問題檢查（靜態）：
    - 使用 VS Code diagnostics 檢查三個修改檔案皆無錯誤。
    - 檢查結果：No errors found。
  - 執行方式：
    - 以診斷工具對以下檔案執行錯誤檢查：
      - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue`
      - `Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue`
      - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`

- performance-impact:
  - 圖表切換時會更常重建單一圖表實例，CPU/GPU 短暫負載略增。
  - 實務上僅發生於使用者切換圖表型別，對整體頁面常駐效能影響低。

- impact-risk:
  - 影響範圍：Dashboard 中所有使用 DashboardComponent 的圖表切換流程。
  - 潛在風險：若某些組件依賴既有圖表內部暫態（selection/tooltip state），重建後會重置。
  - 降級策略：可回退 DashboardComponent 的 `chartRenderKey` key 拼接調整。

- regression-test:
  - 在食安儀表板中切換 `AnimatedColumnChart` 與其他圖表，確認每次切回動畫仍有平滑過渡。
  - 在同一 dashboard 內切換不同組件後返回，確認圖表型別維持使用者最後選擇。
  - 在 map 互動後返回 dashboard，確認圖表型別不會非預期回到預設。
  - 桌機與行動版各驗證一次（至少 Chrome 最新版）。

- traceability:
  - N/A

- next-actions:
  - 建議補一個 e2e 測試：記錄 chart type 切換後 reload/component remount 仍維持型別。
