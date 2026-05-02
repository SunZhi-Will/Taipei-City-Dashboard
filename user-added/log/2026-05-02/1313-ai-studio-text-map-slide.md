# AI Studio 新增文字頁與地圖資料頁 / AI Studio Text & Data-Map Slide Types

## 2026-05-02 13:13

- objective:
  - 讓 AI Agent 能在輪播中安排純文字分析頁（`text` 類型）與帶資料層的地圖頁（`map` 類型強化）

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js

- summary:
  - **新增 `text` 投影片類型（全端）**：`text` 為純文字分析頁，支援 `title`、`subtitle`（由 `summary` 映射）、`highlight`（關鍵數字大字顯示）、`bullets`（最多 5 條重點列）。BE struct 新增 `Bullets []string`、`Highlight string`；`normalizeDisplayPlan` 加入 `"text": true` 白名單；FE `resolveSceneFromDisplayPlan` 與 `sanitizeScene` 同步映射 `bullets`/`highlight`；Canvas 新增 `v-if="slide.type === 'text'"` 渲染塊與獨立 CSS。
  - **強化 `map` 投影片的地圖資料層顯示**：原本 `map` 類型若未設定 `chart_type` 預設為 `"map"` 字串，可能無法驅動 DashboardComponent 顯示正確的地圖圖層。修正為三層降級策略：① 使用 `slide.chartType`（若已是 map 類型）→ ② 從組件的 `chart_config.types` 尋找第一個 map 類型（`map_legend`/`map_pin`/`map_heat`/`map_layer`/`map_district`）→ ③ 降級為 `map_legend`。BE normalizeDisplayPlan 預設也改為 `map_legend`。
  - **AI prompt 更新**：`injectInstructions` 的 AI Studio 段落說明 `text` 與 `map` 類型用法；JSON 範例新增完整的 `text`、`map` 投影片示範，確保 LLM 知道如何填寫 `bullets`、`highlight`、`chart_type`。

- change-type:
  - Added
  - Changed

- technical-details:
  - `resolveChartTypeForSlide(slide, component)` helper：僅對 `map` 類型觸發；若 `slide.chartType` 已在 `MAP_CHART_TYPES` 集合中則直接使用；否則查 `component.dashboardConfig.chart_config.types` 陣列取第一個匹配值；都不符合時 fallback 到 `map_legend`。`MAP_CHART_TYPES = Set(['map_legend', 'map_pin', 'map_heat', 'map_layer', 'map_district'])`。
  - `text` 投影片的 `slide-main--text` 使用 `flex + justify-content: center` 垂直居中，不同於 `hero`（`grid + place-items: center`），以便多條 bullets 不會溢出。`highlight-value` 使用 JetBrains Mono + `text-shadow: 0 0 24px rgba(56,189,248,0.45)` 強調視覺焦點。
  - `isUnknownSlideType` 加入 `text`，避免未知類型 fallback 渲染覆蓋 text 投影片。
  - BE `DisplayPlanSlide` struct 新增 `Bullets []string` (`json:"bullets,omitempty"`)、`Highlight string` (`json:"highlight,omitempty"`)；`omitempty` 確保不影響不使用這兩欄的現有投影片類型。

- verification:
  - `get_errors`：全部 4 個修改檔案均無錯誤
  - 邏輯驗證：`resolveChartTypeForSlide` 對 `component` 類型投影片回傳 `slide.chartType || ''`，不影響現有圖表行為

- impact-risk:
  - `bullets`/`highlight` 欄位在舊場景中為空陣列/空字串，Canvas 的 `v-if` 判斷確保不渲染多餘 DOM，無回歸風險
  - `map` 投影片 chart_type 從 `"map"` 改為 `"map_legend"` 預設：若組件支援的 map 類型不是 `map_legend`，`resolveChartTypeForSlide` 的第二層降級會使用組件自身的 map 類型，`map_legend` 只在完全無法偵測時才作 fallback

- regression-test:
  - 確認現有 `component` 投影片仍顯示正確圖表類型（`resolveChartTypeForSlide` 對非 map 類型直接回傳 `slide.chartType`）
  - 確認 `map` 投影片顯示地圖圖層而非空白或圖表
  - 確認 `text` 投影片顯示 title、highlight（大數字）、bullets 清單
  - 確認 `hero` 與 `component_explain` 投影片外觀不受影響

- traceability:
  - 接續 user-added/log/2026-05-02/1235-ai-studio-carousel-complete.md

- next-actions:
  - 建議：可在 `syncMapLayersForSlide` 加入 `text` 類型的 early return 排除（目前已有 `slide.type !== 'map'` 判斷，已足夠）
  - 建議：`text` 投影片的 `highlight` 可考慮加入動畫數字遞增效果（countUp），但優先級低
