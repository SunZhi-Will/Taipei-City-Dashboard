# AI Agent 端到端強化 / AI Agent End-to-End Hardening

## 2026-04-24 18:12

- objective:
  - 依使用者要求全面實作，避免再出現「顯示 JSON 給使用者」與「display_plan 格式漂移導致輪播異常」問題。

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - 後端在 `finalize()` 內改為同時處理：
    - 以原始 LLM 回覆萃取 `display_plan`。
    - 將使用者可見答案剝離 JSON 區塊（保留自然語言摘要）。
  - 新增 `stripDisplayPlanFromAnswer()`，避免回傳包含 ` ```json ` 規劃區塊到前端。
  - `tryParseDisplayPlan()` 新增 `normalizeDisplayPlan()`，對 AI 產生的計畫做 schema 修復：
    - 強制 `mode=presentation`、`strict_render=true`。
    - slide 只接受 `component/map`，無效類型過濾。
    - `duration_sec` 正規化（預設 12，上限 30）。
    - `type=map` 且無 `chart_type` 時自動補 `map`。
    - 若 `blocks` 缺漏，自動依 `slides` 反推最小可用 blocks。
  - 前端新增 `stripDisplayPlanBlock()`，做第二道保險，確保 UI 不顯示規劃 JSON。
  - `queryByTwai()` 與 minimal fallback 分支都套用內容清理。

- change-type:
  - Changed

- technical-details:
  - `buildDisplayPlan()` 仍維持 AI-first，fallback second；但現在 AI 輸出解析後會先經 schema normalization 再使用。
  - `finalize()` 內先算 `agentResult`，避免重複計算並確保 `displayPlan` 與 `agentResult` 一致性。
  - 內容清理策略：
    - 優先切 ` ```json ` 前的文字。
    - 若無 fenced block，嘗試以 `"mode"` 向前回溯 `{` 去除裸 JSON 段。

- verification:
  - `get_errors` 檢查以下檔案均為 `No errors found`：
    - `Taipei-City-Dashboard-BE/app/services/ai/ai_service.go`
    - `Taipei-City-Dashboard-FE/src/services/aiChatService.js`
    - `Taipei-City-Dashboard-BE/app/models/componentConfig.go`
    - `Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go`

- impact-risk:
  - 若未來 LLM 不輸出 JSON 或格式大幅偏離，仍會走 fallback display plan，不會中斷。
  - 目前未在本機做 Go binary build（環境缺少 go 指令），採用靜態診斷驗證。

- regression-test:
  - 驗證 AI 回覆末尾含 `display_plan` JSON 時，聊天室只顯示自然語言、不顯示 JSON。
  - 驗證 `slides` 出現異常型別時，normalize 後不會導致前端輪播空白。
  - 驗證 map 類型投影片具 `chart_type=map`，可被前端投影片邏輯正確辨識。

- traceability:
  - Related logs:
    - user-added/log/2026-04-24/1810-ai-agent-display-plan-intelligence-upgrade.md

- next-actions:
  - N/A
