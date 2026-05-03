# AI 數據落地工具鏈全面實作 / Full Implementation of Data-Grounded AI Tooling

## 2026-04-24 16:09

- objective:
  - 解決 AI 僅推薦元件但未依據實際圖表資料回答的問題。
  - 建立兩段式工具鏈：先檢索元件，再抓取元件圖表資料後生成回答。

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/controllers/ai.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - 新增後端工具 `get_component_chart_data`，可依 `component_id/city/time_from/time_to` 取得對應組件圖表資料。
  - 工具整合至現有 registry，讓 TWAI Agent 可在同一回合內調用。
  - 強化前端 system prompt 與 tool schema，要求「數值/趨勢問題」必須先取回實際資料再回答。
  - 新增 `answer_mode=agent_data_grounded`，區分是否已進入資料落地回答。

- change-type:
  - Fixed

- technical-details:
  - 在 `registry.go` 註冊 `get_component_chart_data`，並以既有 `models.GetComponentChartDataQuery` + 四種資料解析函式（two_d/three_d,time/map_legend）回傳結構化 JSON。
  - 在 `ai_service.go` 的指令注入新增規則：數值與趨勢類問題必須採用 sequential tool calls（retrieve -> chart data）。
  - 在 `aiChatService.js` 新增 FE tools 宣告，使模型可見 `get_component_chart_data` 的參數結構。
  - 在 `controllers/ai.go` 新增 answer mode 判斷優先序，當偵測到 `get_component_chart_data` 即標記 `agent_data_grounded`。

- verification:
  - 使用 VS Code diagnostics 檢查以下檔案：
    - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
    - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
    - Taipei-City-Dashboard-BE/app/controllers/ai.go
    - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - 結果：以上檔案均為 `No errors found`。

- performance-impact:
  - 預期影響：每次數值型提問可能增加一次工具呼叫，回覆延遲小幅上升。
  - 預期收益：回答正確性與可驗證性顯著提升，降低僅推薦元件的空泛回答比例。

- impact-risk:
  - 風險：若某 component query 資料量過大，可能造成 token 使用上升。
  - 緩解：預設 time range 為近 30 天，並保留既有 fallback 機制。

- regression-test:
  - 以同一提問測試「一般敘述型」與「數值/趨勢型」兩類問題，確認工具路徑切換。
  - 觀察回傳 `tools` 與 `answer_mode` 是否符合預期（包含 `agent_data_grounded`）。
  - 驗證 chat widget 與 ai_studio 兩入口行為一致。

- traceability:
  - related conversation task: 使用者需求「全面實作」
  - previous analysis: AI 工具鏈僅檢索元件，未抓圖表資料

- next-actions:
  - 增加 `get_component_history_data` 工具，支援更完整趨勢比較。
  - 後台 KPI 面板納入 `agent_data_grounded` 與 tool_timeline 指標。
