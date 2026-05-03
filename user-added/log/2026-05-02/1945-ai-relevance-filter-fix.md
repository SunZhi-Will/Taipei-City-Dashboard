# AI 搜尋主題相關性過濾修正 / AI Search Topic-Relevance Filter Fix

## 2026-05-02 19:45

- objective:
  - 修正 AI 助理在回覆「交通壅塞」、「全市年齡分區」等查詢時，不當將「雙北空氣品質監測站」納入推薦清單的問題
  - 根本原因：向量相似度模型對部分組件的 embedding 過於泛化，導致空氣品質測站在不相關的查詢中仍得到 ≥0.82 的分數（如：「交通壅塞」→ 0.8284；「全市年齡分區」→ 0.8242），超過原始閾值 0.78，被 LLM 直接採用
  - LLM 無主題相關性判斷指令，見到分數符合即納入推薦

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **BE `ai_service.go`**：在 `injectInstructions()` 的系統提示第 8 條新增「主題相關性自我檢查」規則，明確指示 LLM 收到 retrieve_components_by_query 結果後，必須逐一判斷每組件是否與查詢主題直接相關；顯然屬於不同領域的組件必須排除，且不得呼叫其 get_component_chart_data
  - **BE `tools/registry.go`**：將 `RetrieveComponentsByQuery` 的預設 score 閾值從 0.78 提高到 0.82，減少語義漂移組件進入 LLM 候選集的機率
  - **FE `aiChatService.js`**：同步修正工具 score 參數說明（default 0.78 → 0.82，retry 0.72 → 0.75）及系統提示的主題相關性過濾指令（原範例描述方向錯誤，已更正為精確描述問題方向：查「交通」出現「空氣品質」等）

- change-type:
  - Fixed

- technical-details:
  - 問題根源：`air_station_map_metrotaipei` 組件的 `use_case` 包含「行政區」「外出決策」等通用詞，使其 384 維 ONNX embedding 向量與交通、人口分布等主題的查詢向量餘弦相似度超過 0.82
  - 修正架構：採「LLM 後處理過濾」方案（而非重建 Qdrant 索引），透過系統提示新增明確的領域排除指令，讓 LLM 在生成回覆前自行做最後一道相關性篩選
  - 新增的系統提示規則（BE 版本）：「若某組件名稱或描述顯然屬於不同主題領域（例如：查詢「交通」卻出現「空氣品質」；查詢「年齡分布」卻出現「地圖測站」），必須將該組件從推薦清單中排除，不得展示給使用者，也不得呼叫 get_component_chart_data 取得其數據。」
  - 首尾頁格式：系統提示已有「每次回覆以親切開場白開始（例如「您好！」），並以鼓勵繼續詢問的結語作結」，測試確認輸出包含 首頁「您好！」和 尾頁「若您有其他問題，歡迎繼續詢問！」

- verification:
  - 測試環境：本機 docker (dashboard-be port 8088)，模型 llama3.3-ffm-70b-16k-chat
  - 測試指令：
    ```
    curl -X POST http://localhost:8088/api/v1/ai/chat/twai \
      -H "Authorization: Bearer $TOKEN" \
      -d '{"session":"test-xxx","messages":[...],"tools":[...]}'
    ```
  - **查詢「交通壅塞」**（修正前：空氣品質出現；修正後）：
    - 向量搜尋仍回傳 [0.8284] 雙北空氣品質監測站 作為第 1 名
    - AI 最終回覆：4 組件（自行車道路網圖資、電動巴士比例、YouBike使用情況、自行車道路統計資料），**空氣品質組件完全不出現**
    - 有首頁「您好！」，有尾頁鼓勵繼續詢問
  - **查詢「全市年齡分區」**（修正前：空氣品質出現；修正後）：
    - 向量搜尋仍回傳 [0.8242] 雙北空氣品質監測站 作為第 5 名
    - AI 最終回覆：4 組件（全市年齡分區、高齡就業人口之年增結構、扶養比及老化指數、長照指標），**空氣品質組件完全不出現**
    - 有首頁「您好！以下是與「全市年齡分區」相關的組件：」，有尾頁

- performance-impact:
  - LLM 推理不受影響（主題過濾為 in-context reasoning，不增加 tool call 次數）
  - 提高閾值 0.78 → 0.82 使第一次搜尋結果集略微縮小，但相關性更高
  - 測試延遲：~21s（與修正前相同數量級）

- impact-risk:
  - 若某查詢的所有相關組件分數都低於 0.82（原本 0.78 可命中），可能導致第一次搜尋空結果；但 LLM 會自動以 score 0.75 重試
  - 主題相關性判斷由 LLM 執行，極端情況下 LLM 可能過度排除；可透過調整系統提示範例來修正
  - FE lint 錯誤（pre-existing，非本次修改引入）導致前端 Docker image 無法 rebuild；FE 改動在 aiChatService.js 中已寫入，下次有效 FE build 時生效

- regression-test:
  - 重新測試所有語意接近的交叉主題查詢：「空氣品質」、「人口結構」、「交通流量」、「老年照護」
  - 確認空氣品質查詢本身能正常返回空氣品質組件
  - 確認首頁「您好！」和尾頁「若有其他問題，歡迎繼續詢問！」在所有標準查詢中出現

- traceability:
  - 相關 log：user-added/log/2026-04-24/1810-ai-agent-display-plan-intelligence-upgrade.md
  - 問題觸發：使用者回報「AI 為什麼思考會把空氣品質給加進去」
  - N/A（無對應 PR/ticket）

- next-actions:
  - [P2] 考慮對 air_station_map_metrotaipei 等泛化組件重新產生更具辨別性的 long_desc/use_case 文字後重建 Qdrant 向量索引，從根本解決 embedding 語意漂移
  - [P2] 修正前端 pre-existing lint 錯誤，讓 FE Docker image 可正常建置
  - [P3] 新增 AI 回覆主題排除的 unit test（Go test file）
