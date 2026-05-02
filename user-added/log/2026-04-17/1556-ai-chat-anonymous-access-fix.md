# 修正 AI 對話未登入被誤判忙碌 / Fix AI Chat Fallback Caused by Login Gate

## 2026-04-17 15:56

- objective:
  - 修正前端一直顯示「AI 對話服務暫時忙碌，已自動切換為組件推薦模式」的實際根因。
  - 讓未登入使用者也可直接使用 `/api/v1/ai/chat/twai`，避免 403 觸發誤導性 fallback。

- files:
  - Taipei-City-Dashboard-BE/app/routes/router.go
- summary:
  - 移除 AI 路由群組上的 `middleware.IsLoggedIn()`，改為匿名可呼叫。
  - 保留原有限流中介層（`LimitAPIRequests` / `LimitTotalRequests`），維持基本保護。
- change-type:
  - Fixed
- technical-details:
  - 原行為：`/api/v1/ai/chat/twai` 在 `configureAIRoutes()` 內受 `IsLoggedIn()` 保護，未登入回應 403。
  - 新行為：`/api/v1/ai/chat/twai` 直接掛在 `aiRoutes` 下，不要求登入。
  - 安全性：全域 `ValidateJWT` 仍會注入匿名 context（`accountID=0`），控制器可正常執行。
- verification:
  - 語法檢查：`get_errors` 檢查 `Taipei-City-Dashboard-BE/app/routes/router.go`，No errors found。
  - 容器重啟：`docker restart dashboard-be` 後服務正常啟動。
  - 實測 API（未登入）：
    - `POST http://localhost:8088/api/v1/ai/chat/twai`
    - HTTP 200
    - 回傳 `{"status":"success", ... "answer_mode":"agent_chat" ...}`
- performance-impact:
  - 無明顯效能衝擊；僅移除登入檢查，不新增計算路徑。
- impact-risk:
  - 風險：匿名可使用 AI，流量可能上升。
  - 緩解：目前仍保有限流；若需更嚴格可再加 IP/來源白名單或 captcha。
- regression-test:
  - 未登入前端頁面送出聊天，應取得 AI 回覆而非 fallback 提示。
  - 已登入情境下應維持原有 AI 對話能力。
  - 確認限流仍生效（高頻請求時有被限制）。
- traceability:
  - N/A
- next-actions:
  - 觀察匿名流量與錯誤率；若量升高再補 anti-abuse（IP 限制/風險控制）。
