# MapView 獨立全螢幕與動態島重構 / MapView Standalone Fullscreen and Dynamic Island Refactor

## 2026-04-23 14:29

- objective:
  - 將 mapview 改為獨立頁面，移除全域左側導覽與上方原導覽列對地圖視野的壓縮
  - 實作全版地圖 + 自訂上方導覽（左上圓形 Logo、右上動態導覽）
  - 實作左側懸浮動態島：私人/公共兩層展開、公共城市下拉、第三層項目展開與組件勾選同步地圖

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - App 版型調整：`/mapview` 改為獨立 fullscreen layout，不再套用 `NavBar + SideBar + SettingsBar` 主框架
  - MapView 全面改寫為新殼：
  - 1) 地圖全寬全高（MapContainer 佔滿畫面）
  - 2) 上方自訂導覽列（圓形 Logo 返回 dashboard + 右側 menu 顯示原導覽中的兩個主要連結）
  - 3) 左側懸浮動態島（可收合），含私人/公共儀表板分組
  - 4) 公共儀表板新增城市下拉（臺北/雙北）並依選項渲染第三層儀表板清單
  - 5) 每個儀表板可展開，顯示其組件清單與 checkbox，同步控制 map layer 開關
  - 6) 取消「僅當前儀表板可勾選」限制，改為所有展開項目都可直接勾選同步 map

- change-type:
  - Changed

- technical-details:
  - App.vue:
    - `NavBar` 顯示條件排除 `mapview`
    - 新增 `app-mapview-layout`，專門承載 mapview full-height RouterView
    - 原 `app-content` 分支改為僅 dashboard 使用
  - MapView.vue:
    - 移除舊有 DashboardComponent 左欄卡片排版，改為資料導向控制島 UI
    - 新增 dashboard 組件快取 `dashboardComponentsCache`，展開儀表板時按需呼叫 `/dashboard/{index}`
    - 新增分層 state：private/public/favorites/personal 展開控制、public city 選擇、dashboard 展開映射
    - 新增 map sync checkbox 邏輯：
      - 勾選 -> `mapStore.addToMapLayerList(component.map_config)`
      - 取消 -> `clearByParamFilter + turnOffMapLayerVisibility`
    - checkbox 狀態改為純 `componentToggles` 控制，不再依賴「是否為 current dashboard」條件
    - 保留聊天帶入地圖能力：監聽 `query.openComponentId` 並自動開啟對應圖層

- verification:
  - 使用 VS Code diagnostics 檢查：
  - Taipei-City-Dashboard-FE/src/App.vue -> No errors found
  - Taipei-City-Dashboard-FE/src/views/MapView.vue -> No errors found
  - 額外檢查使用者提醒檔：Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue（確認現況仍為 height:auto 的 halfmapopen）

- performance-impact:
  - 地圖可視範圍提升（移除框架固定占位）
  - 儀表板組件資料改為展開時按需載入，降低初始渲染壓力
  - 新增前端快取，避免同一 dashboard 重複請求

- impact-risk:
  - 新 UI 流程與舊版側欄操作模式不同，使用者需短暫適應
  - 私人儀表板因資料結構包含跨 city 組件，已做去重策略（優先 taipei）但仍可能與舊視圖排序微差
  - mobile 目前沿用 hide-if-mobile 隱藏上方/左側浮層，手機端仍以 MapContainer 既有交互為主

- regression-test:
  - 驗證項目：
  - 1) 進入 /mapview 時不顯示全域 NavBar/SideBar，地圖滿版
  - 2) 點左上 Logo 可返回 /dashboard
  - 3) 右上 menu 可展開並導到「儀表板總覽 / 組件瀏覽平台」
  - 4) 左側動態島可收合/展開
  - 5) 公共城市下拉切換臺北/雙北後，第三層儀表板清單切換正確
  - 6) 展開儀表板後可見組件清單，checkbox 可同步地圖圖層
  - 6-1) 不切換目前儀表板也可直接勾選其他儀表板中的組件同步地圖
  - 7) 從聊天帶 `openComponentId` 進入 mapview 可自動啟用對應圖層

- traceability:
  - Related request: 使用者要求「Map 獨立頁、全滿版地圖、上方自訂導覽、左側動態島雙層展開與勾選同步 map」
  - Related logs:
  - user-added/log/2026-04-23/1416-mapview-uiux-overhaul.md
  - user-added/log/2026-04-23/1418-mapview-watch-brace-syntax-fix.md

- next-actions:
  - 建議進行實機視覺驗收（desktop 1366/1440 + ultrawide）
  - 若要進一步貼近「動態島」效果，可再加 sticky 區塊彈性高度與分段動畫（P1）
