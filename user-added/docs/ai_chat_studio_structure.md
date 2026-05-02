# AI Chat 與 AI Studio 深度分析說明文件

本文件提供「台北城市儀表板」AI 系統的深度技術分析，涵蓋組件結構、底層工具鏈 (Tools)、AI 思考路徑、資料豐富化 (Data Hydration) 以及前端渲染機制。

---

## 1. 系統架構全景 (Full System Architecture)

AI 系統採用 **Agentic RAG (檢索增強生成代理)** 架構，並非單純的問答模型。

### 1.1 分層架構
- **UI 層 (Frontend)**: 使用 Vue 3 + Pinia。負責對話狀態維護與「場景 (Scene)」的視覺化。
- **協調層 (Backend Controller)**: Go (Gin) 實作。處理 Session 管理、IP 追蹤、以及與 TWCC (Taiwan Computing Cloud) AFS 的 API 對接。
- **服務層 (Agent Logic)**: 核心 `ai_service.go`。實作 Tool-calling 循環 (Max 5 loops)，負責將 LLM 的意圖轉化為實際的資料庫查詢。
- **能力層 (Tools)**: 註冊於 `registry.go` 的工具集，提供向量檢索、即時圖表數據、人口統計數據等。

---

## 2. 核心組件與資料流 (Detailed Data Flow)

### 2.1 請求生命週期
1. **Frontend**: 用戶輸入問句，`aiChatService.js` 會注入當前的 `Scene` 狀態作為 context（讓 AI 知道畫布上已有什麼）。
2. **Backend**: `ChatWithTWCC` 接收請求，生成 `SessionID` 並驗證權限。
3. **Agent Loop**:
    - **Step A**: LLM 生成 `tool_calls`。
    - **Step B**: Backend 執行 `tools.Execute`。
    - **Step C**: 將工具結果 (JSON 格式) 餵回 LLM。
    - **Step D**: 重複直到 LLM 決定產出最終回答。
4. **Finalization**: 後端擷取 LLM 回覆中的 `display_plan` JSON，進行圖表類型校驗 (Chart Type Correction) 後回傳。

### 2.2 Session 管理
- **Session ID**: 前端使用 `sessionStorage` 儲存隨機 UUID。
- **對話記憶**: 後端限制最多 12 則訊息上下文，以避免超過 LLM 的 Token 限制並維持回應品質。

---

## 3. AI 工具鏈 (Tooling Schema)

以下為 AI 可呼叫的底層工具及其參數定義：

| 工具名稱 | 參數 (Arguments) | 輸出內容 | 邏輯說明 |
| :--- | :--- | :--- | :--- |
| `retrieve_components_by_query` | `query`, `limit`, `score` | 匹配組件清單 (含 ID, HasMap, ChartTypes) | 使用 e5 Embedding 模型在 Qdrant 進行語義搜尋。 |
| `get_component_chart_data` | `component_id`, `city`, `time_from`, `time_to` | 二維/三維/時間序列數據 + 自動摘要 (Summary) | 從 PostgreSQL 提取數據，並自動生成 `summary` 供 AI 填充表格。 |
| `get_population_summary` | `city`, `year` | 幼/青/老 人口結構與總數 | 針對人口議題的專門工具，直接查詢統計表。 |
| `get_current_time` | (無) | 台北標準時間 | 讓 AI 能計算「過去 30 天」等相對時間範圍。 |

---

## 4. AI Studio 指揮中心邏輯 (The "Director" Persona)

在 AI Studio 模式下，AI 被賦予了「指揮中心導演 (War-room Director)」的指令：

### 4.1 思考路徑 (Director's Thinking Path)
1. **理解意圖**: 判斷是「數據查詢」還是「專題簡報」。
2. **素材挑選**: 透過 `retrieve_components_by_query` 獲取組件，排除不相關的主題。
3. **策劃流暢度**:
    - **Hero Slide**: 作為專題開場。
    - **Component Slide**: 核心數據展示。
    - **Map Slide**: 若組件 `has_map` 為 true，則配置地圖層。
    - **Explain Slide**: 用於解讀數據背後的政策意涵。
    - **Text Slide**: 總結與洞察。

### 4.2 展示計畫 (Display Plan) 規格
AI 生成的 JSON 計畫必須符合以下投影片類型：
- `type: "component"`: 渲染 `DashboardComponent`。
- `type: "map"`: 渲染 Mapbox 互動地圖。
- `type: "text"`: 提供 `summary`, `bullets`, `highlight` 欄位進行大字報展示。
- `type: "hero"`: 滿版標題與副標題。

---

## 5. 補償與容錯機制 (Robustness & Fallbacks)

### 5.1 圖表類型自動修正 (Chart Type Correction)
這是系統穩定性的關鍵。AI 常會寫出 `bar` 而非系統定義的 `BarChart`。
- **邏輯**: 後端 `fixSlidesChartTypes` 會查詢資料庫中該組件真實支援的類型列表。
- **策略**: 若 AI 指派的類型不在列表中，則利用 `pickBestChartType` 進行語義匹配（例如將 `pie` 對應到 `DonutChart`）。

### 5.2 前端 Fallback
若 AI 完全沒有產出 `display_plan`（例如連線中斷或模型異常）：
- **邏輯**: 前端 `aiChatService.js` 中的 `buildFallbackScene` 會根據推薦組件清單，自動組裝一個基礎的「圖表牆」場景。

---

## 6. 前端渲染邏輯 (Frontend Rendering)

### 6.1 資料豐富化 (Hydration)
從 AI 拿到的只是 ID。前端必須：
1. 呼叫 `/api/v1/component/:id/all` 取得組件配置。
2. 呼叫 `/api/v1/component/:id/chart` 取得圖表數據。
3. 根據 `aiStudioStore` 的 `Scene` 配置，將數據傳遞給視圖組件。

### 6.2 互動地圖處理
在 `AIStudioView.vue` 中：
- 地圖層 (`MapContainer`) 與畫布 (`Canvas`) 是分開層級的。
- 當投影片類型為 `map` 時，畫布會變為半透明玻璃材質，透出底層的 Mapbox 地圖，實現沉浸式體驗。

---

## 7. 相關原始碼索引 (Final Directory Reference)

- **AI 控制中心**: `Taipei-City-Dashboard-BE/app/services/ai/ai_service.go`
- **工具定義**: `Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go`
- **向量檢索邏輯**: `Taipei-City-Dashboard-BE/app/models/qdrant.go`
- **前端對話服務**: `Taipei-City-Dashboard-FE/src/services/aiChatService.js`
- **場景狀態管理**: `Taipei-City-Dashboard-FE/src/store/aiStudioStore.js`

---
*文件更新於：2026年5月。由 Taipei City Dashboard 開發團隊維護。*
