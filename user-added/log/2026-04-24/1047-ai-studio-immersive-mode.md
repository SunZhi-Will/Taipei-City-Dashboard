# AI Studio 全螢幕沉浸模式 / Add AI Studio Immersive Fullscreen Mode

## 2026-04-24 10:47

- objective:
  - 讓 AI Studio 的輪播展示、圖表牆、地圖可切換為全螢幕觀看，並在全螢幕時移除全域導覽干擾，只保留目前觀看區塊內容。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 在 AI Studio 工具列新增全螢幕入口，會針對目前選中的模式進入沉浸式觀看。
  - 全螢幕時隱藏上方 NavBar、手機底部導覽、AI Studio 聊天側欄與工具列，只保留內容區與離開全螢幕控制。
  - 讓沉浸模式可透過 route query 控制，避免影響其他頁面路由邏輯。

- change-type:
  - Fixed

- technical-details:
  - 在 App.vue 新增 `isAIStudioImmersive` 計算屬性，依 `/ai-studio?fullscreen=1` 條件隱藏全域 NavBar 與 mobile bottom nav。
  - 在 AIStudioView.vue 導入 `useRoute` 與 `useRouter`，以 `fullscreen=1` query 作為沉浸模式旗標。
  - 新增 `setImmersiveMode()` 控制 query 切換，避免新增額外 store 狀態。
  - 沉浸模式下關閉左側聊天面板、工具列與 JSON drawer，改為浮動 badge 與退出按鈕，讓輪播展示、圖表牆、地圖都只顯示主內容。
  - 補上沉浸模式專用背景、overlay 與內容區高度樣式，確保桌機與窄螢幕都有可用的退出控制。

- verification:
  - `get_errors` 檢查：Taipei-City-Dashboard-FE/src/App.vue、Taipei-City-Dashboard-FE/src/views/AIStudioView.vue 皆為 `No errors found`。
  - `node -e "const fs=require('fs'); const { parse, compileTemplate } = require('@vue/compiler-sfc'); ..."`：對 App.vue 與 AIStudioView.vue 逐一執行 Vue SFC parse/compileTemplate，兩者皆無 parse/template errors。
  - `npx vite build`：未通過，Vite 回報一個現行前端編譯流程中的 Vue expression `SyntaxError`；但直接編譯本次修改的兩個 SFC 檔案皆成功，表示本次變更至少未在這兩個檔案中引入模板解析錯誤。

- performance-impact:
  - 僅新增少量 query 判斷與樣式切換，無額外 API 請求。
  - 對渲染成本影響極低，主要為條件式顯示與 CSS overlay。

- impact-risk:
  - 低至中風險：主要影響 AI Studio 頁面版面切換與導覽顯示條件。
  - 若其他地方後續也使用 `fullscreen` query，需避免語意衝突。
  - 地圖模式仍依賴既有 map 資源初始化；若未先初始化，沉浸模式仍只會顯示既有空狀態提示。

- regression-test:
  - 驗證 AI Studio 三種模式下，點擊全螢幕後是否隱藏全域導覽與聊天側欄。
  - 驗證離開全螢幕後，原本的模式與內容是否完整保留。
  - 驗證手機窄版時，進入全螢幕後底部導覽不再顯示，且退出按鈕可正常操作。

- traceability:
  - N/A

- next-actions:
  - 1. 在瀏覽器實際檢查 AI Studio 三種模式的全螢幕互動與版面比例。
  - 2. 若要讓使用者直接從外部連結打開指定模式全螢幕，可再補 `mode` query deep-link。
