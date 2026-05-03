# AI Studio 輪播極簡化調整 / Simplify AI Studio Presentation UI

## 2026-04-24 10:58

- objective:
  - 將 AI Studio 輪播展示改為更簡約的資訊呈現，進一步移除多餘留白、裝飾與重複控制。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 移除輪播中的背景光暈、網格、AI badge 與 hero 重複文案，避免首頁看起來空且雜。
  - 對 component slide 隱藏外層 caption，並將 DashboardComponent 的 footer、fullscreen 按鈕與多餘間距在 presentation 模式下縮減。
  - 壓縮 stage、panel、chart 容器與左右控制的尺寸，讓畫面更貼近極簡 signage 風格。

- change-type:
  - Fixed

- technical-details:
  - 刪除模板中的 `canvas-bg-glow`、`canvas-mesh-grid` 與 `ai-badge`，保留最小必要的 slide pagination。
  - 將 hero slide 改為只顯示 `slide.title` 與 `slide.subtitle`，不再額外渲染 `hero-message-card` 造成重複訊息與空白。
  - 將 `presentation-stage` padding、`slide-content` padding、`chart-glass-base` padding、左右箭頭與 dots 尺寸整體縮小。
  - 透過 `:deep()` 覆寫 presentation 內的 `DashboardComponent`：隱藏 `dashboardcomponent-footer`、`dashboardcomponent-header-button`、`.fullscreen-btn`，並縮小 header/control 區間距。
  - 對 hero slide 加上 `slide-main--hero` 與 `slide-info--hero`，採集中且簡短的版面，不再用大卡片包裝訊息。

- verification:
  - `get_errors`：Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue 回報 `No errors found`。
  - `node -e "const fs=require('fs'); const { parse, compileTemplate } = require('@vue/compiler-sfc'); ..."`：直接檢查 AIStudioPresentationCanvas.vue，結果為 `parse errors: []`、`template errors: []`。
  - `npx eslint src/components/ai-studio/AIStudioPresentationCanvas.vue`：已無 blocking error，但仍有既有/局部模板排版 warnings（主要是 `vue/html-indent` 與 attribute order），本次未為了格式警告擴大重排模板。

- performance-impact:
  - 僅減少模板節點與視覺裝飾，對效能為輕微正向影響。
  - 無新增 API、無新增資料處理流程。

- impact-risk:
  - 低風險：僅限於 AI Studio 輪播展示元件的視覺與排版。
  - presentation 模式會隱藏 DashboardComponent footer 與 fullscreen 控制；若之後需要在輪播內保留這些操作，需改為條件開關。

- regression-test:
  - 驗證第一張 hero slide 是否只保留標題與副標，且不再出現額外訊息卡。
  - 驗證 component slide 是否去除多餘 caption，圖表內容區變大。
  - 驗證左右箭頭、頁碼與 dots 在桌機與手機尺寸下仍可正常操作。
  - 驗證 DashboardComponent 在一般 dashboard 頁面未被這些 `:deep()` presentation 覆寫影響。

- traceability:
  - N/A

- next-actions:
  - 1. 若還想更極簡，可再把 slide 頂部頁碼也收成右下角小型浮標。
  - 2. 若輪播用途偏 kiosk，可再把左右箭頭改成 hover 才出現，預設只留 autoplay 與進度條。
