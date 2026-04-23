# 地圖型組件聊天顯示修正 / Map Component Chat Render Fix

## 2026-04-23 14:07

- objective:
  - 修正聊天推薦中「地圖型組件」被當成圖表預覽，導致使用者看到空圖表樣式、無法正確理解資料型態的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 新增地圖型組件判斷（依 dashboardConfig.map_config 是否存在）並在聊天結果中改為地圖卡顯示，不再直接走圖表預覽。
  - 新增「開啟地圖」按鈕事件，從聊天卡片導向 mapview，讓地圖資料回到地圖檢視流程。
  - 保留原本非地圖組件的圖表預覽與相關指標互動行為。

- change-type:
  - Fixed

- technical-details:
  - ChatResultComponents:
    - 增加 hasMapConfig 與 isMapComponent 判斷。
    - 調整 isDashboardPreview，排除 map component，避免誤用 DashboardComponent 圖表預覽。
    - 新增 open-map emit 與地圖卡 UI（map-focus-card + map-open-btn）。
  - ChatBox:
    - 新增 handleOpenMap，接收 map component 後導向路由 name=mapview。
    - query 參數使用 component.dashboardConfig.city 與 currentDashboard.index（缺省回退 map-layers/taipei）。
    - 將 @open-map 綁定到 ChatResultComponents。

- verification:
  - 使用 VS Code diagnostics 檢查以下檔案無錯誤：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - 檢查方式：get_errors 工具，結果皆為 No errors found。

- performance-impact:
  - 本次為渲染分支與事件綁定調整，無新增大型計算與輪詢。
  - 預期對首屏與互動效能影響可忽略。

- impact-risk:
  - 低風險：僅影響聊天結果區塊的組件型態呈現。
  - 已知邊界：若推薦組件不在目前 dashboard index 下，mapview 仍可能無對應圖層；此情境目前先導向 mapview，由使用者在地圖頁選擇。

- regression-test:
  - 建議回歸項目：
    - 一般圖表型推薦仍維持原有大卡預覽。
    - 地圖型推薦改顯示地圖卡，點擊「開啟地圖」可導向 /mapview。
    - /mapview 原有地圖圖層切換與圖表卡互動不受影響。

- traceability:
  - N/A

- next-actions:
  - P1: 在 mapview 增加「從聊天導入自動高亮/開啟指定圖層」能力，消除跨 dashboard index 的定位落差。
