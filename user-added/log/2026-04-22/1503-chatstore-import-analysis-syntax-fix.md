# 修正聊天狀態庫匯入分析語法錯誤 / Fix Chat Store Import-Analysis Syntax Error

## 2026-04-22 15:03

- objective:
  - 修正 Vite `import-analysis` 因 `chatStore.js` 非法語法導致的編譯中斷，恢復聊天功能載入。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 清除 `queryByTwai` 區塊中誤貼入的重複/截斷程式碼片段（包含錯置的 `return` 與巢狀邏輯）。
  - 重建 `for` 重試流程與 `try/catch` 邊界，保留原有重試策略與 fallback 行為。
  - 補齊回應空值檢查（`EMPTY_RESPONSE`、`EMPTY_CONTENT`）避免不完整資料造成後續錯誤。

- change-type:
  - Fixed

- technical-details:
  - 調整 `queryByTwai(question)` 內部控制流程：
  - 以 `TWAI_MAX_RETRY` 迴圈搭配 `shouldRetry` 與遞增等待時間，失敗時正確拋錯。
  - 將回應解析集中於成功路徑，統一輸出 `{ ok, content, answerMode, tools }`。
  - 保留 minimal context recovery：若主要請求失敗，使用 `createPayload(false)` 再嘗試一次。

- verification:
  - 執行語法檢查：`node --check Taipei-City-Dashboard-FE/src/store/chatStore.js`（通過，無輸出）。
  - IDE 問題檢查：`get_errors` 針對 `chatStore.js` 回報 `No errors found`。

- performance-impact:
  - 此修正不引入額外網路請求次數上限變更；僅恢復既有重試與 fallback 控制流。
  - 預期效能影響可忽略，主要收益為避免編譯失敗與啟動阻斷。

- impact-risk:
  - 影響範圍：前端聊天狀態管理與 AI 回應流程。
  - 已知風險：若後端回傳 schema 再次變動，仍可能觸發 `EMPTY_CONTENT` fallback；已透過既有向量推薦 fallback 降級。

- regression-test:
  - 建議驗證聊天流程：
  - 1) 送出一般問題，確認 bot 正常回覆。
  - 2) 模擬 AI 服務失敗，確認回落至向量推薦流程。
  - 3) 重新整理頁面後確認 sessionStorage 聊天紀錄仍可讀寫。

- traceability:
  - Related runtime error: `[plugin:vite:import-analysis] Failed to parse source ... chatStore.js:1:1`
  - Log: user-added/log/2026-04-22/1503-chatstore-import-analysis-syntax-fix.md

- next-actions:
  - N/A
