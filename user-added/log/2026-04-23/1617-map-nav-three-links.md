# 地圖頁膠囊導覽修正為三連結 / Fix Map Capsule Navigation to Three Links

## 2026-04-23 16:17

- objective:
  - 修正地圖頁上方膠囊導覽與需求不一致的問題，避免出現重複且語意錯誤的返回連結。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue
- summary:
  - 將地圖頁膠囊導覽由「儀表板總覽 + 返回儀表板（重複語意）」調整為三個主要入口。
  - 新增 mapRoute 與 aiStudioRoute，與 dashboardRoute 一樣保留 index/city query，維持使用者上下文。
  - 導覽項目調整為：儀表板總覽、地圖交叉比對、AI Studio。
- change-type:
  - Fixed
- technical-details:
  - 在 Vue Composition API 中新增兩個 computed route 物件：mapRoute、aiStudioRoute。
  - mapRoute 使用 name: "mapview"；aiStudioRoute 使用 path: "/ai-studio"，兩者皆條件帶入 route.query.index 與 route.query.city。
  - 模板中的 nav.map-nav-capsule 移除 auth token 條件的「組件平台」與「返回儀表板」項目，替換為固定三連結。
- verification:
  - 使用問題診斷檢查檔案：get_errors Taipei-City-Dashboard-FE/src/views/MapView.vue
  - 診斷結果：No errors found。
  - 文字檢查：確認模板區塊存在三個 map-nav-link，分別指向 dashboardRoute、mapRoute、aiStudioRoute。
- performance-impact:
  - 新增兩個 computed，僅依 route.query 生成小型物件，效能影響可忽略。
- impact-risk:
  - 風險：若 AI Studio 路由後續不接受 query，仍可能帶入多餘參數。
  - 緩解：目前 Vue Router 可正常處理未知 query；若未來規格限制，可在 aiStudioRoute 移除 query 轉傳。
- regression-test:
  - 在 mapview 頁面確認膠囊導覽顯示三個連結。
  - 點擊「儀表板總覽」可返回 dashboard 並保留 index/city。
  - 點擊「地圖交叉比對」維持在 mapview 並保留 index/city。
  - 點擊「AI Studio」可進入 ai-studio，URL query 仍保留 index/city。
- traceability:
  - N/A
- next-actions:
  - 若要完全對齊全站主導覽，可再評估是否加入 active 狀態樣式與權限導向版本。

- [x] 本次修正已新增 user-added/log/YYYY-MM-DD/HHmm-標題.md
- [x] 日期、時間、檔案、摘要、驗證、風險、traceability 七要素完整
- [x] change-type 使用標準分類（Added/Changed/Fixed/Removed/Security）
- [x] 路徑符合 user-added/log/YYYY-MM-DD/HHmm-title.md
- [x] 標題符合「中文 / English」雙語格式
