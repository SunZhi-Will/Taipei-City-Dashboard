# AI Studio 空白投影片止血修復 / AI Studio Empty Slide Fallback Fix

## 2026-04-24 13:57

- objective:
  - 修復 AI Studio 簡報輪播中 component 類型投影片出現空白頁（DOM 只有 v-if 註解、不渲染內容）的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - user-added/log/2026-04-24/1357-aistudio-empty-slide-fallback-fix.md

- summary:
  - 強化投影片到組件的對應邏輯：先以 focusComponentId 對映，失敗後再以 title 對映，再退回依投影片索引推測組件。
  - 為 component 投影片新增保底渲染：當找不到 dashboardConfig 時顯示可讀提示卡，而非整頁空白。
  - 同步新增空白狀態樣式，確保 UI 在資料缺失時仍可辨識與操作。

- change-type:
  - Fixed

- technical-details:
  - 在 `AIStudioPresentationCanvas.vue` 新增 `componentByName` 計算屬性，支援標題名稱級別對映。
  - `getSlideComponent(slide, slideIndex)` 改為多路解析：
    - `focusComponentId` -> `componentById`
    - `slide.title` -> `componentByName`
    - `slideIndex` 對應 `props.components` 的穩健 fallback
  - template 內將 `getSlideComponent` 呼叫補入 index，避免只靠 id 對映。
  - 新增 `slide-component-empty` 區塊處理 `slide.type === 'component'` 且缺少 `dashboardConfig` 情境。

- verification:
  - 執行 VS Code diagnostics：
    - `get_errors` for `Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue`
    - 結果：No errors found。
  - 靜態檢查模板條件：component 類投影片在「有 config」與「無 config」均有對應渲染分支，不會全空。

- performance-impact:
  - 新增的 name map 與 fallback 判斷為 O(n) 建表 + O(1) 查找，對現有投影片數量影響可忽略。

- impact-risk:
  - 低風險：主要為容錯渲染與對映補強，不改後端契約。
  - 已知風險：若 `slide.title` 與組件名稱高度同名，可能命中非預期組件；已以 `focusComponentId` 優先並保留索引 fallback 降低風險。

- regression-test:
  - 建議回歸項目：
    - AI Studio 有 display_plan + 完整 components 時，投影片順序與內容正確。
    - AI Studio 有 display_plan 但部分 component config 缺失時，顯示提示卡而非白頁。
    - map / hero / component_explain 三類投影片仍正常渲染。

- traceability:
  - Related: AI Studio 輪播空白頁使用者回報（本次對話）

- next-actions:
  - 建議後續在 store/service 層補齊 `focusComponentId` 與 components 的一致性檢查與 telemetry，追蹤 id 對映失敗率。
