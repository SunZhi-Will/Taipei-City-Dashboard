# AI Studio 輪播版面去重與縮減留白 / Refine AI Studio Presentation Layout to Reduce Whitespace and Duplicate Content

## 2026-04-24 10:51

- objective:
  - 優化 AI Studio 輪播展示中的元件型 slide，降低左右與上方空白，並移除與內嵌 DashboardComponent 重複的標題資訊。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 將元件型 slide 改為圖表優先版面，不再使用大段標題區塊擠壓主畫面。
  - 當 slide 標題與 DashboardComponent 標題相同時，外層標題不再重複顯示。
  - 放寬 component slide 的玻璃面板最大寬度與內容內距配置，讓全螢幕輪播更接近真正的大畫面展示。

- change-type:
  - Fixed

- technical-details:
  - 新增 `getSlideComponent()` 取得當前 slide 對應的 component，避免模板重複查表。
  - 新增 `normalizeText()` 與 `shouldShowComponentTitle()`，當 slide.title 與 dashboard component 名稱語意相同時隱藏外層標題，避免重複顯示「長照指標」這類資訊。
  - 保留 `slide.subtitle` 作為精簡 caption，移至圖表容器上緣，減少主內容區被標題區塊占用。
  - 對 component slide 增加 `slide-glass-panel--component` 與 `slide-content--component`，將最大寬度放寬至 `min(1480px, calc(100vw - 72px))`，並縮小不必要邊距。
  - 元件 slide 的 `slide-main` 間距由大段資訊區改為緊湊式 caption + chart 結構，讓圖表佔比更高。

- verification:
  - `get_errors`：Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue 回報 `No errors found`。
  - `node -e "const fs=require('fs'); const { parse, compileTemplate } = require('@vue/compiler-sfc'); ..."`：直接對 AIStudioPresentationCanvas.vue 執行 Vue SFC parse 與 compileTemplate，結果皆為 `parse errors: []`、`template errors: []`。

- performance-impact:
  - 僅調整模板條件顯示與樣式配置，無新增 API 或重量級運算。
  - 字串比對邏輯僅在單一 slide render 中使用，成本可忽略。

- impact-risk:
  - 低風險：影響範圍限於 AI Studio 輪播展示元件。
  - 若未來 slide.title 需刻意與 component 標題重複呈現，現行去重邏輯會隱藏外層標題，屆時需再加上 override 旗標。

- regression-test:
  - 驗證元件型 slide 在桌機全螢幕下圖表可視區是否明顯放大。
  - 驗證 slide.title 與元件標題相同時，畫面上只保留一份主標題。
  - 驗證 hero/closing 類 slide 仍維持原本的大標敘事版面。
  - 驗證手機或窄視窗下 caption 與圖表不會互相擠壓。

- traceability:
  - N/A

- next-actions:
  - 1. 若仍覺得 DashboardComponent 內部 header 過重，可再加入 presentation mode 專屬 props，進一步弱化元件自身 header/footer。
  - 2. 若輪播主要用於大螢幕 signage，可再補自動隱藏左右切換按鈕的 kiosk 模式。
