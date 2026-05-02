# 管理端 AI 統計全面實作 / Admin AI Stats Full Implementation

## 2026-04-17 11:13

- objective:
  - 補齊 Admin-only KPI 監控閉環：Redis 快取、前端統計頁、側欄導航一次落地。

- files:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go
  - Taipei-City-Dashboard-BE/app/controllers/chatlog.go
  - Taipei-City-Dashboard-FE/src/store/adminStore.js
  - Taipei-City-Dashboard-FE/src/router/index.js
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/AdminSideBar.vue
  - Taipei-City-Dashboard-FE/src/views/admin/AdminAiStats.vue

- summary:
  - BE Model: 修正 INTERVAL 參數化（改用 CAST(? AS INTERVAL)），避免 GORM 佔位符失效；補 `fmt` import。
  - BE Controller: `GetChatLogStats` 加 Redis cache（TTL 5 分鐘，key 依 `days` 區分）；cache hit 時回傳 `cached: true`。
  - FE Store: `adminStore` 新增 `aiStats`、`aiStatsDays` state 與 `getAiStats(days)` action。
  - FE Router: 新增 `/admin/ai-stats` 路由，lazy-load `AdminAiStats.vue`。
  - FE AdminSideBar: 在「系統總覽」下方新增「AI 監控」區段與「AI 問答統計」導航項目。
  - FE AdminAiStats.vue: 全新管理頁，包含：
    - 模式摘要卡片（agent_rag / agent_chat / vector_fallback / unknown + 總計）
    - ApexCharts 折線圖（依日期 + 模式分群）
    - 逐日明細表（含 Badge 標示）
    - 區間選擇（7/14/30/60/90 天）與重新整理按鈕

- change-type:
  - Added

- verification:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go: No errors found
  - Taipei-City-Dashboard-BE/app/controllers/chatlog.go: No errors found
  - Taipei-City-Dashboard-FE/src/store/adminStore.js: No errors found
  - Taipei-City-Dashboard-FE/src/router/index.js: No errors found
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/AdminSideBar.vue: No errors found
  - Taipei-City-Dashboard-FE/src/views/admin/AdminAiStats.vue: No errors found

- impact-risk:
  - 全為新增，不修改現有流程；路由受 router guard 保護，非 admin 無法進入。
  - Redis 快取若失效，直接 fallback 至 DB 查詢，不影響可用性。

- traceability:
  - Related: user-added/log/2026-04-17/1106-admin-chatlog-kpi-stats-api.md
  - Related: user-added/log/2026-04-17/1101-chatlog-answer-mode-and-tools-persistence.md

- next-actions:
  - P1: 手動驗證 /admin/ai-stats 在 admin 帳號可正常載入圖表。
  - P2: 擴充 tool_call_ratio 與 rag_hit_rate 獨立指標（需 used_tools 欄位統計）。
