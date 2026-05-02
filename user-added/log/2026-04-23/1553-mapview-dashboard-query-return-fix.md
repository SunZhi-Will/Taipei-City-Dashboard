# 修正地圖頁返回儀表板路由參數遺失 / Fix MapView Return-to-Dashboard Query Loss

## 2026-04-23 15:53

- objective:
  - 修正從 mapview 返回 dashboard 時遺失 index/city query，導致 dashboard 回落到預設儀表板與錯誤側欄狀態的問題。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 新增 dashboardRoute computed，從當前 mapview route.query 保留 index 與 city。
  - MapView 左上返回按鈕與上方兩個返回 dashboard 連結改為導向帶 query 的 dashboard 路由。
  - 避免 contentStore 在 /dashboard 初始化時因缺少 query 而重新選到第一個可用儀表板。

- change-type:
  - Fixed

- technical-details:
  - MapView 原本使用 router.push('/dashboard') 與 to="/dashboard"，未帶回 route.query.index / route.query.city。
  - router.beforeEach 進入 /dashboard 時會呼叫 contentStore.setRouteParams(to.path, to.query.index, to.query.city)。
  - 當 index 不存在時，contentStore.setDashboards() 會 fallback 到第一個可用 dashboard，造成畫面內容與左側選單看起來像切到別的主題。
  - 本次改為 computed route object：若 mapview 有 index/city，就一起帶回 dashboard。

- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/views/MapView.vue
  - 結果：No errors found。
  - 程式碼檢查：確認 MapView 返回 dashboard 的三個入口均改為使用 dashboardRoute / returnToDashboard。

- performance-impact:
  - 無顯著效能影響。
  - 僅新增一個輕量 computed route object。

- impact-risk:
  - 低風險：變更範圍僅限 mapview 返回 dashboard 的導頁邏輯。
  - 若 mapview 本身沒有 query，仍會安全地回到不帶 query 的 dashboard。

- regression-test:
  - 從 /mapview?index=ltc_care_tpe&city=taipei 點返回儀表板，確認回到 /dashboard?index=ltc_care_tpe&city=taipei。
  - 驗證左側選單維持在臺北儀表板 > 長照關懷，不回落到預設第一個儀表板。
  - 驗證 MapView 左上 logo 與上方 capsule 內兩個 dashboard 連結行為一致。

- traceability:
  - N/A

- next-actions:
  - 可再做一次實際瀏覽器點擊驗證，確認 URL 與側欄狀態同步恢復。