# AI Studio Agent 展示頁全面實作 / Full AI Studio Agent Presentation Implementation

## 2026-04-23 18:42

- objective:
  - 將 AI Studio 從組件推薦畫布升級為 Agent 可自動生成右側展示畫面的系統。
  - 支援大螢幕情境下的輪播展示與形象頁風格輸出，符合校園/政府展示需求。

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 擴充 AI 場景生成邏輯：依使用者語句判斷展示意圖與產業主題，生成 presentation scene（含 slides、autoplay、industry）。
  - 擴充 AI Studio Store schema：新增 presentation 欄位與 slides sanitize，並新增 presentation mode。
  - 新增 AIStudioPresentationCanvas：提供橫向輪播、投影片切換、播放/暫停、產業主題背景與組件嵌入渲染。
  - 更新 AIStudioView：加入模式切換工具列，整合 presentation mode，讓 AI 回覆可直接驅動右側展示頁。

- change-type:
  - Changed

- technical-details:
  - aiChatService fallback scene 新增 showcase intent 偵測（輪播/形象/看板/大螢幕關鍵詞），可在缺少 LLM scene JSON 時仍輸出可展示場景。
  - scene 內新增 presentation 結構：
    - style: carousel | briefing | component-grid
    - autoplay: enabled + intervalMs
    - audience: public-screen
    - industry: transport | senior-care | education | health | general
    - slides: hero/component/closing 組合，含 focusComponentId。
  - AIStudioPresentationCanvas 使用 scene 與 component map 進行投影片渲染，並以 setInterval 實作自動切換節奏。
  - AIStudioView 工具列加入輪播展示/圖表牆/地圖模式切換，並保留 Scene JSON 檢視。

- verification:
  - 使用靜態錯誤檢查確認本次修改檔案皆無錯誤：
    - get_errors Taipei-City-Dashboard-FE/src/services/aiChatService.js
    - get_errors Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
    - get_errors Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
    - get_errors Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - 針對本次改動檔案執行 lint：
    - npx eslint src/services/aiChatService.js src/store/aiStudioStore.js src/views/AIStudioView.vue src/components/ai-studio/AIStudioPresentationCanvas.vue
  - 檢查結果：以上檔案皆通過，No errors found。

- performance-impact:
  - 新增 presentation 自動輪播計時器，僅在 presentation mode 且 slides > 1 時啟動，降低不必要背景輪詢。
  - 組件渲染維持既有 DashboardComponent，避免重複資料抓取流程帶來額外後端負擔。

- impact-risk:
  - 風險：部分 scene JSON 若由外部模型輸出且欄位不完整，可能需依 sanitize 規則補值。
  - 邊界：當無組件且無 slides 時會顯示空狀態提示，不影響主流程。
  - 降級：可切回 components mode 以維持既有使用體驗。

- regression-test:
  - 建議測試項目：
    - AI Studio 對話輸入「交通輪播展示」後右側是否切至 presentation 並自動播放。
    - 輸入一般查詢是否仍可在 components mode 正常渲染組件。
    - map mode 切換後地圖容器是否正常。
    - 手機寬度下 presentation footer 按鈕是否可操作。
  - 驗證環境：本機 FE 開發環境（Vite）。

- traceability:
  - N/A

- next-actions:
  - P1: 將 presentation slides 的決策邏輯從規則式升級為 Planner/Designer/Director 三 Agent JSON pipeline。
  - P2: 新增「看板播放清單管理」與多螢幕策略（平日/假日/活動模式）。
