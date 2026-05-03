# 組件查詢主結果與相關候選修正 / Agentic Primary-Related Component Rendering Fix

## 2026-04-22 16:07

- objective:
  - 修正 AI 查組件時「未明確選主結果」與「誤以單一結果覆蓋需求」問題。
  - 強化當模型未呼叫檢索 tool 時的前端保底檢索流程，避免只回文字不帶原生組件資料。

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - 將組件結果策略改為「主結果 + 相關候選」，移除 direct intent 下可能僅回傳 1 筆的邏輯。
  - 新增 `isPrimary` 標記並在 UI 顯示「主結果 / 相關候選」標籤。
  - 新增 `shouldRetrieveComponents` 條件：當使用者語意屬於查組件/指標，即使 model 沒回報 `retrieve_components_by_query`，仍執行檢索與 hydration。
  - 更新 system prompt，要求查組件類問題需先檢索再回答，並以主次結果形式輸出。

- change-type:
  - Fixed

- technical-details:
  - `selectFocusedComponents` 由可能回單筆改為固定挑選前 3~4 筆並附 `isPrimary`。
  - `addQueryData` 新增語意保底判斷，降低 tool call 漏觸發導致的空結果風險。
  - `ChatResultComponents.vue` 針對每張卡片新增 result label，強化可解釋性。

- verification:
  - 診斷檢查：`get_errors` 檢查以下檔案皆為 No errors。
    - Taipei-City-Dashboard-FE/src/store/chatStore.js
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue
  - API 可達性檢查：`Invoke-WebRequest http://localhost:8080/api/dev/component/218/all` 回傳 `200`。

- performance-impact:
  - 在 component intent 且 model 未呼叫 tool 的情境下，可能新增一次檢索/詳情查詢；平均延遲略增。
  - 以結果上限（3~4）控制輸出與渲染成本，避免無上限卡片造成 UI 壓力。

- impact-risk:
  - 若意圖判斷過寬，部分一般問答也可能觸發檢索，造成額外 API 呼叫。
  - 已透過關鍵詞判斷與結果上限緩解；仍建議後續改為後端結構化決策輸出。

- regression-test:
  - 針對「扶養比及老化指數」、「長照」等查組件問題，驗證是否顯示主結果與候選。
  - 針對純知識問答問題，驗證不應出現不相關組件卡片。
  - 驗證 dashboard 組件可正常以 `DashboardComponent mode=preview` 呈現。

- traceability:
  - N/A

- next-actions:
  - 將 `primary_component`、`related_components`、`selection_reason` 下放為後端 AI 結構化回傳契約。
  - 將 endpoint fallback 收斂為單一路徑，避免環境差異造成 404。
