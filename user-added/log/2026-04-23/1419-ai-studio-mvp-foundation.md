# 新增 AI Studio 獨立頁與 Scene 模板基礎 / Add AI Studio Page and Scene Template Foundation

## 2026-04-23 14:19

- objective:
  - 建立獨立 AI 頁面，實作左側可收合 Chat + 右側可切換畫布（組件/地圖/網頁）
  - 將 AI 回覆結構化為 scene JSON，作為可重用的展示配置輸出
  - 在 MVP 階段納入模板儲存、套用與刪除能力

- files:
  - Taipei-City-Dashboard-FE/src/router/index.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 新增 /ai-studio 路由，提供獨立 AI 展示頁入口
  - 新增 aiStudioStore 管理 scene、右側模式切換、左欄收合與模板持久化
  - 新增 AIStudioView：整合 ChatBox、DashboardComponent、MapContainer 與 web iframe 畫布
  - 在 chatStore 新增 scene JSON 解析與 fallback scene 生成，讓 bot 回覆附帶可渲染 scene
  - 手機窄螢幕允許進入 ai-studio 路由，避免被既有路由守衛擋下

- change-type:
  - Added
  - Changed

- technical-details:
  - scene schema 採 split layout 結構，核心欄位包含 version/title/objective/layout/blocks/meta
  - 右側畫布模式以 scene.layout.rightPanel.mode 控制，支援 components/map/web
  - 模板使用 localStorage（key: ai_studio_templates_v1）進行 client-side 持久化
  - chatStore 先嘗試從 AI 文字抽取 JSON（fenced code or inline object），失敗則以推薦組件自動產生 fallback scene
  - fallback scene 會帶入組件 id/index/city，供前端直接渲染

- verification:
  - 問題檢查：get_errors 檢查新增/修改檔案，確認 AIStudioView、aiStudioStore、chatStore、router 無語法錯誤
  - 建置驗證：於 Taipei-City-Dashboard-FE 執行 npm run build
  - 建置結果：失敗（非本次修改引入）
  - 失敗細節：
    - src/App.vue:66 no-unused-vars（formattedTimeToUpdate）
    - src/store/adminStore.js:69 no-unused-vars（e）
    - vite.config.js.timestamp-1776849597140-142e5e197255.mjs no-undef（process）
  - 本次新增代碼相關 lint 已修正：chatStore 的 regex 與未使用 catch 變數

- performance-impact:
  - 新增頁面為路由級載入，僅在進入 /ai-studio 時初始化對應 UI 邏輯
  - 模板操作使用 localStorage，為 O(templates) 的輕量讀寫，預設上限 30 筆
  - scene JSON 顯示為純前端序列化，對既有 dashboard/mapview 影響低

- impact-risk:
  - 風險：MapContainer 在 ai-studio 內使用時，與既有 mapview 流程有狀態耦合可能
  - 風險：web iframe 可能受目標網站 X-Frame-Options 限制而無法嵌入
  - 緩解：保留三種右側模式切換，iframe 失效時仍可用組件/地圖模式

- regression-test:
  - 手動測試建議：
  - 1) 進入 /ai-studio，確認左側可收合與聊天可用
  - 2) 觸發 AI 推薦組件後，確認右側 components 畫布可渲染
  - 3) 切換 map/web 模式，確認畫布可切換且不崩潰
  - 4) 儲存模板、刷新頁面、重新套用模板，確認持久化有效
  - 5) 手機窄螢幕下直接打開 /ai-studio，確認不被強制重導

- traceability:
  - related-request: 使用者決策確認（模板=要、scene JSON=是）
  - log-id: user-added/log/2026-04-23/1419-ai-studio-mvp-foundation.md

- next-actions:
  - P0: 將 scene schema 抽成 shared contract，前後端共用驗證器（zod/jsonschema）
  - P1: 新增「由 scene 直接產生展示頁 URL」能力，支援跨城市快速複製
  - P1: 補 E2E 測試覆蓋 ai-studio 模板流與模式切換
