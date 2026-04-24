# AI fallback 錯誤語意修正 / AI Fallback Error Semantics Fix

## 2026-04-24 16:26

- objective:
  - 修正 AI 對話失敗時一律顯示「服務忙碌」的誤導訊息，避免把設計問題誤判為 API 壅塞。

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js

- summary:
  - 新增統一的 fallback 訊息建構函式，依 `reason` 類型輸出不同文案（429、網路逾時、空回覆、4xx、5xx）。
  - Chat Widget 與 AI Studio 都改為使用統一函式，不再硬編碼「AI 對話服務暫時忙碌」。
  - 使 UI 訊息與真實失敗型態對齊，提升排障可觀測性與使用者信任度。

- change-type:
  - Fixed

- technical-details:
  - 在 `aiChatService.js` 新增 `buildTwaiFallbackNotice(reason)`。
  - 規則分流：
    - `HTTP_429` -> 流量較高
    - `NETWORK_OR_TIMEOUT` -> 網路或逾時
    - `EMPTY_CONTENT/EMPTY_RESPONSE` -> 回覆內容不可用
    - `HTTP_4xx` -> 請求未通過
    - `HTTP_5xx` -> 服務回應異常
  - `chatStore.js` 與 `aiStudioChatStore.js` 的 fallback 訊息改由該函式統一產生。

- verification:
  - `get_errors` 檢查以下檔案均為 `No errors found`：
    - `Taipei-City-Dashboard-FE/src/services/aiChatService.js`
    - `Taipei-City-Dashboard-FE/src/store/chatStore.js`
    - `Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js`

- performance-impact:
  - 僅增加輕量字串分支判斷，效能影響可忽略。

- impact-risk:
  - 低風險：僅修改前端 fallback 文案策略，不影響 API 請求流程。
  - 仍維持原有 fallback 到向量推薦，功能不中斷。

- regression-test:
  - 模擬 `reason` 為 `HTTP_429`、`NETWORK_OR_TIMEOUT`、`EMPTY_CONTENT`，確認文案對應正確。
  - 驗證 Chat Widget 與 AI Studio 兩入口在失敗時訊息一致。

- traceability:
  - Related log: user-added/log/2026-04-24/1618-ai-chat-fallback-root-cause-and-hardening.md

- next-actions:
  - 可進一步將 `reason` 一併寫入前端 telemetry，建立錯誤碼分佈儀表板（P1）。
