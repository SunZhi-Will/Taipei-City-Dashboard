# 管理端 ChatLog KPI 統計 API / Admin ChatLog KPI Stats API

## 2026-04-17 11:06

- objective:
  - 提供管理員專用的 AI 問答模式分佈統計（agent_chat / agent_rag / vector_fallback），支援 RAG hit rate 計算。
  - 限制為 SysAdm 才可存取，一般使用者無法呼叫。

- files:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go
  - Taipei-City-Dashboard-BE/app/controllers/chatlog.go
  - Taipei-City-Dashboard-BE/app/routes/router.go

- summary:
  - Model: 新增 `ChatLogStatRow` 結構體與 `GetChatLogStats(days)` 函式，對 `chat_logs` 做日期 + answer_mode 分群聚合查詢。
  - Controller: 新增 `GetChatLogStats` handler，接受 `?days=N`（預設 30，上限 365），回傳 `total / totals / daily` 三層結構。
  - Router: 在 `configureChatLogRoutes()` 內新增 admin 子群組，套用 `IsSysAdm()` 中介層，掛上 `GET /chatlog/stats`。

- change-type:
  - Added

- verification:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go: No errors found
  - Taipei-City-Dashboard-BE/app/controllers/chatlog.go: No errors found
  - Taipei-City-Dashboard-BE/app/routes/router.go: No errors found
  - 路由保護確認：`IsSysAdm()` 已在 admin 子群組上，一般登入使用者呼叫時會回 403。

- impact-risk:
  - 僅新增唯讀 API，不修改任何現有資料流。
  - 一般使用者無法存取（401/403 強制回應）。
  - `GetChatLogStats` 查詢可能在資料量大時有效能壓力，建議後續加 Redis 快取（TTL 5 分鐘）。

- traceability:
  - Related: user-added/log/2026-04-17/1101-chatlog-answer-mode-and-tools-persistence.md

- next-actions:
  - P1: 加上 Redis 快取，避免管理端頻繁查詢拖慢 DB。
  - P1: 在管理端前端頁面消費此 API，繪製 answer_mode 趨勢圖。
  - P2: 擴充 API 支援 `tool_call_ratio`（用了工具的比例）與 `rag_hit_rate`（retrieve 觸發比例）細節。
