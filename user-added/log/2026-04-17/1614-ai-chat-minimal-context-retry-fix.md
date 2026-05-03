# AI 對話最小上下文補救重試 / AI Chat Minimal-Context Recovery Retry

## 2026-04-17 16:14

- objective:
  - 降低使用者提問（如「高齡就業」）時 AI 請求偶發失敗後直接 fallback 的機率。
  - 在完整歷史上下文失敗時，增加一次最小上下文補救呼叫，提升成功率。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
- summary:
  - `buildTwaiMessages` 新增 `includeHistory` 參數，支援只送 system + 本次 user 問題。
  - `queryByTwai` 新增 `createPayload(includeHistory)`，把 payload 建構標準化。
  - 原請求失敗後，新增 recovery path：改用 minimal context 再呼叫一次 `/ai/chat/twai`。
  - minimal context 模式將 `max_new_tokens` 下調至 256，降低複雜度與延遲。
- change-type:
  - Fixed
- technical-details:
  - 保留既有 2 次重試機制（針對 408/429/5xx 與 network error）。
  - 若重試後仍失敗，才進入 minimal-context fallback request。
  - 若 minimal-context 有有效內容，視為 AI 成功回覆，不進 vector fallback。
- verification:
  - VS Code diagnostics:
    - `Taipei-City-Dashboard-FE/src/store/chatStore.js` -> No errors found
  - 前端容器重啟後 Vite 正常啟動。
- performance-impact:
  - 僅在原請求失敗時才有額外一次 AI 呼叫。
  - 成功情境無新增負擔，失敗情境以一次補救換取較高成功率。
- impact-risk:
  - 低風險，僅前端 AI 請求策略調整。
  - 極端連續失敗時，仍會走既有 vector fallback，行為可預期。
- regression-test:
  - 連續提問「HI」→「高齡就業」，確認不易再立即出現忙碌 fallback。
  - 模擬網路抖動時，確認最終仍可 fallback 且畫面不中斷。
- traceability:
  - related-log:
    - user-added/log/2026-04-17/1608-ai-chat-fallback-resilience-fix.md
- next-actions:
  - 若仍有少量失敗，建議增加前端上報 `reason` 指標（HTTP/timeout）做量化監控。
