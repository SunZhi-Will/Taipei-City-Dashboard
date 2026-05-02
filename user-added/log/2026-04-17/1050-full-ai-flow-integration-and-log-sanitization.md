# 變更紀錄：AI 主流程整合與日誌去敏 / Change Log: AI Primary Flow Integration and Log Sanitization

## 2026-04-17 10:50

- objective / 目標:
  - 將前端聊天主流程從單一向量推薦升級為「AI 對話優先 + 向量推薦備援」。
  - 降低後端 AI provider 日誌的敏感資料暴露風險。
  - 在不破壞現有 UI 互動的前提下，完成可灰度上線的整合版本。

- files / 修改檔案:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - Taipei-City-Dashboard-BE/app/services/ai/providers/twcc/twcc.go
  - user-added/log/2026-04-17/1050-full-ai-flow-integration-and-log-sanitization.md

- summary / 變更摘要:
  - FE: 在 chatStore 新增 AI 主流程控制，預設啟用對話式 API（/ai/chat/twai），並保留向量推薦作為 fallback。
  - FE: 新增 `VITE_USE_TWAI_CHAT` 功能開關，支援快速回退至舊流程。
  - FE: 新增對話上下文組裝（最近訊息 + system prompt），並注入最小可用 tools 定義。
  - FE: 當 AI 失敗時自動顯示提示並切換到向量推薦，維持使用者連續體驗。
  - FE UI: 更新 ChatBox 置頂公告文字，說明雙模式與 fallback 行為。
  - BE: TWCC provider 請求/回應 log 從原始內容輸出改為摘要輸出（model、stream、message count、tool count、bytes）。

- technical-details / 技術細節:
  - `chatStore.js`
    - 新增 `USE_TWAI_CHAT` 與 `MAX_CONTEXT_MESSAGES` 常數。
    - 將 `addQueryData` 改為：優先呼叫 `queryByTwai`，失敗則執行 `queryByVector`。
    - 新增 `buildTwaiMessages()`：將既有 user/bot 訊息轉為 `user/assistant` 角色，保留最近上下文。
    - 新增 `queryByTwai()`：發送 JSON payload 至 `/ai/chat/twai`，含 `tools` + `tool_choice=auto`。
    - 抽離 `queryByVector(question)`，讓備援路徑可重用原本推薦能力。
  - `ChatBox.vue`
    - 更新 sticky 公告內容，反映「AI 對話優先，服務忙碌時自動備援」。
  - `twcc.go`
    - 將 `TWCC Outgoing Request` 的完整 JSON log 改為安全摘要 log。
    - 將 `TWCC Raw Response` 的完整內容 log 改為只記錄 response bytes。

- verification / 驗證結果:
  - 已執行檔案診斷檢查：
    - Taipei-City-Dashboard-FE/src/store/chatStore.js: No errors found
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue: No errors found
    - Taipei-City-Dashboard-BE/app/services/ai/providers/twcc/twcc.go: No errors found
  - 已確認前端主流程具備：
    - AI 成功時直接回應
    - AI 失敗時自動 fallback 向量推薦
  - 已確認後端日誌不再輸出完整 prompt/response 原文。

- impact-risk / 影響與風險:
  - 影響範圍：聊天體驗主流程、AI provider 日誌策略、使用者公告文案。
  - 正向影響：
    - AI 功能真正成為前端主路徑
    - 服務韌性提升（fallback）
    - 日誌敏感資料風險下降
  - 已知風險：
    - AI 回應風格與舊推薦模式差異可能造成使用者感知變化
    - tools 目前僅最小集合，複雜場景仍可能回落到一般回答
    - 若後端 AI 配置異常，系統會頻繁進入 fallback（需後續監控告警）

- next-actions / 下一步:
  - 新增前端 UX 標記（例如顯示「AI 回答」或「推薦模式」）提高透明度。
  - 追加 AI 端點的成功率與延遲監控指標。
  - 規劃第二批工具（高價值資料查詢）以提升回答可用性。