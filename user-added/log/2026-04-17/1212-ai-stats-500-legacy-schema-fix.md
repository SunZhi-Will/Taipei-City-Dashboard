# AI 問答統計 500 修正（舊資料庫相容） / AI Stats 500 Fix for Legacy Schema

## 2026-04-17 12:12

- objective:
  - 修復管理端「AI 問答模式統計」在舊 `chat_logs` schema 下回傳 500 的問題。
  - 確保舊環境（缺少 `answer_mode` / `used_tools`）仍可穩定提供統計 API。

- files:
  - Taipei-City-Dashboard-BE/app/models/chatlog.go

- summary:
  - 新增 `ensureChatLogAIMetadataColumns()`：在執行寫入或統計前，先檢查並嘗試補齊 `answer_mode`、`used_tools` 欄位。
  - `CreateChatLog` 改為依欄位存在性自動 `Omit` 缺失欄位，避免舊 schema 寫入失敗。
  - `GetChatLogStats` 增加雙路徑：
    - 欄位存在：維持 `answer_mode` 分組統計。
    - 欄位缺失或偵測到欄位錯誤：降級為 `unknown` 單一路徑統計，避免 500。
  - 同步在執行環境套用 SQL 修補（manager DB）新增缺失欄位，恢復完整 mode-level 統計能力。

- change-type:
  - Fixed

- technical-details:
  - Root cause:
    - 後端日誌顯示 `SQLSTATE 42703`：`column "answer_mode" does not exist`（查詢於 `GetChatLogStats`）。
  - Compatibility strategy:
    - Model 層以 `gorm.Migrator().HasColumn` 做 schema capability 檢測。
    - 查詢層提供 fallback SQL，確保舊環境可用性。
    - 寫入層以 `Omit` 避免 insert 打到不存在欄位。
  - Runtime hotfix SQL:
    - `ALTER TABLE chat_logs ADD COLUMN IF NOT EXISTS answer_mode varchar(50) NOT NULL DEFAULT 'unknown';`
    - `ALTER TABLE chat_logs ADD COLUMN IF NOT EXISTS used_tools text NOT NULL DEFAULT '[]';`

- verification:
  - Backend static check:
    - `get_errors` on `app/models/chatlog.go` → No errors found。
  - Runtime evidence:
    - `docker logs dashboard-be` 先前可重現 `SQLSTATE 42703` 及 `/api/v1/chatlog/stats?days=30` 500。
    - 套用 SQL 後，以 DB 直接執行統計查詢（含 `answer_mode`）可正常回傳（0 rows 但無錯誤）。
    - `dashboard-be` 重啟後成功 `building... running...` 並完成 DB/Redis 連線。

- performance-impact:
  - 影響極低。
  - 新增欄位存在檢查為輕量操作，且主要發生在請求路徑的單次邏輯；未引入重型查詢。

- impact-risk:
  - 風險：若 DB 權限不足導致 AddColumn 失敗，仍會走 fallback 路徑（不致 500，但統計會退化為 `unknown`）。
  - 風險：若多節點同時嘗試補欄位，`IF NOT EXISTS` 能降低衝突風險。
  - 邊界：沒有聊天資料時統計回傳空集合屬預期行為。

- regression-test:
  - 驗證 `/api/v1/chatlog/stats?days=7|30|90` 在 admin 下皆為 200。
  - 驗證 AI 對話寫入後，`chat_logs.answer_mode`/`used_tools` 有值。
  - 驗證 Redis cache hit/miss 都能正確回傳（`cached=true/false`）。
  - 驗證非 admin 呼叫 `/chatlog/stats` 仍回 403（授權不退化）。

- traceability:
  - Related: user-added/log/2026-04-17/1113-admin-ai-stats-full-implementation.md
  - Related: user-added/log/2026-04-17/1106-admin-chatlog-kpi-stats-api.md

- next-actions:
  - P0: 以 admin 帳號在前端頁面重新整理 `AI 問答統計`，確認不再出現 500。
  - P1: 在 `MigrateManagerSchema` 補上 AutoMigrate error logging，避免未來 migration 靜默失敗。
  - P2: 加入 migration health check endpoint（或 startup check）輸出欄位狀態。