# 台北城市切換規則調整 / Taipei City Switch Rule Adjustment

## 2026-05-03 02:50

- objective:
  - 修正台北儀表板仍顯示城市切換下拉選單的 UI 行為
  - 確保台北只顯示台北資料，不提供切換到雙北

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/utilities/cityManager.ts

- summary:
  - 將 `taipei` 的 `selectList` 由 `['taipei', 'metrotaipei']` 改為 `['taipei']`
  - 因 `DashboardView` 以 `getSelectList(currentDashboard.city).length === 1` 判斷是否顯示切換，下拉選單在台北儀表板將不再渲染
  - 保留 `metrotaipei` 的 `selectList` 為 `['metrotaipei', 'taipei']`，雙北儀表板仍可切換

- change-type:
  - Changed
  - Fixed

- technical-details:
  - 變更點位於 `CityManager.configs` 的 `taipei` 設定
  - 不改動 DashboardComponent 介面與事件流程，僅調整配置來源，降低回歸風險

- verification:
  - 檔案檢查：`Taipei-City-Dashboard-FE/src/dashboardComponent/utilities/cityManager.ts` 中 `taipei.selectList` 已為 `['taipei']`
  - 規則檢查：`DashboardView` 既有邏輯 `getSelectList(...).length === 1` 會讓台北場景不顯示 select
  - 設計檢查：`metrotaipei.selectList` 未更動，雙北仍保留切換能力

- performance-impact:
  - 無效能影響
  - 僅 UI 狀態判斷資料來源調整

- impact-risk:
  - 若其他頁面依賴「台北可切到雙北」舊行為，將不再成立
  - 目前調整僅針對 city manager 設定，影響面可控

- regression-test:
  - 打開台北儀表板，確認不顯示城市切換下拉
  - 打開雙北儀表板，確認仍顯示城市切換下拉且可切換
  - 切換後確認組件資料與地圖 city 一致

- traceability:
  - related log: user-added/log/2026-05-03/0248-rename-and-split-food-safety-dashboards.md

- next-actions:
  - 可再加上 e2e 檢查：台北 dashboard 不存在 `name='city'` 的 select