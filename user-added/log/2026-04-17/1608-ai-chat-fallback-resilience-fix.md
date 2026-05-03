# AI 對話 fallback 韌性修正 / AI Chat Fallback Resilience Fix

## 2026-04-17 16:08

- objective:
  - 修正使用者在詢問「調取扶養比」等問題時，偶發直接進入 fallback 的不穩定行為。
  - 降低前端因網路抖動/逾時造成的誤判，避免「AI 忙碌」誤訊息頻繁出現。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/router/axios.js
- summary:
  - `queryByTwai` 新增可重試機制（最多 2 次），針對 408/429/5xx 與無 response 的情境做延遲重試。
  - `queryByTwai` 失敗時回傳 `reason`（如 `HTTP_502`、`NETWORK_OR_TIMEOUT`）供後續除錯。
  - `axios` response interceptor 修復 `error.response` 為空時的二次錯誤，避免 `Cannot read ... status`。
  - `axios` 在無狀態碼的網路錯誤下統一顯示「網路異常或請求逾時，請稍後再試」。
- change-type:
  - Fixed
- technical-details:
  - `chatStore.js`:
    - 新增 `TWAI_MAX_RETRY = 2`。
    - 新增 `shouldRetry()`：允許重試 `408/429/500/502/503/504` 與 network error。
    - 新增 `wait()` 做簡短 backoff。
    - 失敗時 `return { ok: false, reason }`。
  - `axios.js`:
    - 先抽 `const status = error?.response?.status`。
    - status 不存在時走網路錯誤分支並直接 reject。
    - default 訊息改為容錯 `error?.response?.data?.message || "動作無法完成"`。
- verification:
  - VS Code diagnostics:
    - `src/store/chatStore.js` -> No errors found
    - `src/router/axios.js` -> No errors found
  - 前端容器重啟後，Vite 正常啟動且 HMR 正常。
- performance-impact:
  - 在失敗情境會增加最多 2 次重試請求，成功情境無額外開銷。
  - 預期可顯著降低瞬時故障導致的 fallback 機率。
- impact-risk:
  - 低風險；僅前端錯誤處理與重試策略調整。
  - 風險點：高頻失敗時會多出重試流量；目前仍在可接受範圍。
- regression-test:
  - 連續提問「HI」與「調取扶養比」，確認不會立即 fallback。
  - 暫時斷網後再送出，確認顯示網路錯誤通知且不拋前端例外。
  - 恢復網路後重試提問，確認可回到 AI 正常回覆。
- traceability:
  - related-log:
    - user-added/log/2026-04-17/1556-ai-chat-anonymous-access-fix.md
- next-actions:
  - 若仍有偶發 fallback，可再加上後端回應碼埋點（前端上報 reason）做精準統計。
