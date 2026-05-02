# 提升 AI Agent 輪播規劃智能 / Upgrade AI Agent Display Plan Intelligence

## 2026-04-24 18:10

- objective:
  - 讓 AI Studio 不只是規則拼接，而是由 AI Agent 根據組件能力（是否地圖、多圖表類型）主動規劃戰情室輪播。

- files:
  - Taipei-City-Dashboard-BE/app/models/componentConfig.go
  - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - 擴充向量檢索資料結構，新增 rich 結果（`chart_types`, `has_map`, `short_desc`），讓 Agent 具備可推理的組件能力資訊。
  - 在 AI Studio 模式的 system instruction 中加入強制規劃流程與 JSON schema，要求 AI 產出 display_plan。
  - 後端改為優先解析 AI 回覆中的 `display_plan` JSON，解析成功即直接作為輪播規劃；失敗才走規則型 fallback。
  - 前端 `resolveSceneFromDisplayPlan` 補上 `slide.chart_type` 映射，讓投影片可指定初始圖表類型。

- change-type:
  - Changed

- technical-details:
  - `componentConfig.go`
    - 新增 `CityComponentScoreRich`。
    - `GetComponentByQueryVector()` 改為包裝 `GetComponentByQueryVectorRich()`。
    - 新增 `GetComponentByQueryVectorRich()`：Qdrant 命中後批次查 DB，補 `chart_types`、`has_map`、`short_desc`。
  - `registry.go`
    - `RetrieveComponentsByQuery()` 改用 rich retrieval，回傳更完整 metadata 給 LLM。
  - `ai_service.go`
    - `DisplayPlanSlide` 新增 `chart_type`。
    - `injectInstructions()` 的 AI Studio 分支新增戰情室輪播規劃規範與 JSON 輸出格式。
    - `finalize()` 改為 `buildDisplayPlan(question, appMode, aiAnswer, agentResult)`。
    - 新增 `extractDisplayPlanJSON()` 與 `tryParseDisplayPlan()`。
    - `buildDisplayPlan()` 改為「先吃 AI JSON、後備規則 fallback」。
  - `aiChatService.js`
    - `resolveSceneFromDisplayPlan()` 補 `chartType: slide?.chart_type`，並將 default `durationSec` 調整為 12 秒。

- verification:
  - `get_errors` 檢查以下檔案，皆回傳 `No errors found`：
    - `Taipei-City-Dashboard-BE/app/models/componentConfig.go`
    - `Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go`
    - `Taipei-City-Dashboard-BE/app/services/ai/ai_service.go`
    - `Taipei-City-Dashboard-FE/src/services/aiChatService.js`
  - 嘗試以 terminal 編譯 Go：當前環境缺少可用 `go` binary，無法進行實際 build（已於風險欄標註）。

- performance-impact:
  - 向量檢索後新增一次批次 metadata 查詢，查詢次數為 1（非 N+1），可接受。
  - Agent 規劃品質提升，可能增加少量 token 成本，但能減少錯誤規劃導致的重試成本。

- impact-risk:
  - 依賴 AI 回覆格式：若模型未輸出合法 JSON，會回退到 fallback 規則。
  - rich metadata 查詢使用 `ANY(ids)`，若未來 limit 放大需關注查詢效能。
  - 本機缺少 Go 編譯器，尚未做實機 build 驗證。

- regression-test:
  - 建議回歸測試：
    - 輸入包含「戰情室/輪播/大螢幕」語意，確認回傳 `display_plan.slides` 不含固定 hero/closing。
    - 含 `has_map=true` 組件時，確認 AI 會產生 `type=map` 投影片。
    - 含多 `chart_types` 組件時，確認會展開多張投影片且 `chart_type` 有值。
    - AI 未輸出 JSON 時，確認 fallback 仍可產生可用投影片。

- traceability:
  - Related previous logs:
    - `user-added/log/2026-04-24/1653-carousel-warroom-intelligence-upgrade.md`

- next-actions:
  - P1：在 AI 回覆文本中移除 JSON 區塊後再回傳給前端顯示，避免使用者看到原始規劃 JSON。
  - P1：加入 display_plan JSON schema 驗證（required fields + type checks）。
  - P2：補 Go build pipeline（CI）確保每次 agent 調整可自動編譯檢查。
