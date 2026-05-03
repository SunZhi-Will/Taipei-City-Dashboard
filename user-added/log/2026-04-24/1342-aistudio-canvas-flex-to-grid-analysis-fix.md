# AIStudio Canvas 高度鏈分析修正（Flex 改 Grid） / AIStudio Canvas Height Chain Fix (Flex-to-Grid)

## 2026-04-24 13:42

- objective:
  - 針對使用者指出 `.aistudio-canvas` 使用 `display: flex` 可能導致內容超高問題進行結構性修正。
  - 保留畫布可用高度，避免移除 flex 後出現「畫面變扁」。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 將 `.aistudio-canvas` 從 flex column 改為 grid row 佈局。
  - 無 JSON 時維持單列 `minmax(0, 1fr)`；有 JSON 時改為兩列 `minmax(0,1fr) + 220px`。
  - `canvas-body` 改為 `height: 100%` 以填滿第一列。
  - `scene-json-drawer` 改為 `height: 100%` 由 grid row 控制高度。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `.aistudio-canvas`
    - `display: flex; flex-direction: column;` -> `display: grid; grid-template-rows: minmax(0, 1fr);`
  - `.aistudio-canvas--with-json`
    - 由子元素 `flex: 1` 改為容器行高定義：`grid-template-rows: minmax(0, 1fr) 220px;`
  - `.canvas-body`
    - `flex: 1` -> `height: 100%`
  - `.scene-json-drawer`
    - `height: 220px` -> `height: 100%`（高度由 grid row 控制）

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue -> No errors found

- performance-impact:
  - 純前端 CSS 版面策略調整，無額外 API/CPU 成本。

- impact-risk:
  - 低風險：影響範圍為 AI Studio 畫布容器與 JSON 抽屜分配。
  - 若第三方樣式依賴舊 flex 行為，可能出現細微差異。

- regression-test:
  - 驗證 `presentation/components/map/web` 四種模式在一般與 immersive 下高度正常。
  - 驗證開啟/關閉 Scene JSON 時，主畫布高度不超出、不卡扁。
  - 驗證輪播首頁 hero 文案位置不再因容器高度鏈錯配而偏移。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍出現偏移，可再針對 `AIStudioPresentationCanvas.vue` 做容器高度 debug overlay（僅開發環境）以量測實際像素差。