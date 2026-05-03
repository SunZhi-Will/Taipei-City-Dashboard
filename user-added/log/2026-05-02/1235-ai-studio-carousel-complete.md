# AI Studio 輪播全面完整化 / AI Studio Carousel Full Implementation

## 2026-05-02 12:35

- objective:
  - 修正 6 個讓 AI Studio 輪播無法完整運作的問題，使展示體驗更專業完整

- files:
  - Taipei-City-Dashboard-FE/src/store/aiStudioStore.js
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - **[Bug Fix] `chartType` 在 `sanitizeScene` 被丟棄** — AI 生成 `display_plan` 時指定每張投影片的圖表類型（如 `bar`、`line`、`map`），這些值經 `resolveSceneFromDisplayPlan` 正確映射為 `chartType`，但 `sanitizeScene` 的 slide 映射未包含此欄位，導致場景存入 store 後 `chartType` 消失，canvas 的 `:initial-chart-type` 永遠是空字串。同步加入 `summary` 欄位保留（語義備援）。
  - **[Bug Fix] autoplay 不尊重每張投影片的 `durationSec`** — 原本 `setupTimer` 使用 `setInterval`，以 scene 層級的 `intervalMs` 作為固定間隔，所有投影片都用同一秒數。hero 投影片通常設定 8-10 秒、資料圖表設定 12-15 秒，但這些設定完全無效。修正：改用 `setTimeout` 遞迴呼叫，每次讀取 `currentSlideDurationMs`（從 active slide 的 `durationSec * 1000`，fallback 至 scene 的 `intervalMs`）。
  - **[Feature] play/pause 按鈕** — `status-footer` 新增暫停/播放切換按鈕（左下角），對應 `isPlaying` ref。進度條底色高度維持 4px，按鈕高度 24px，視覺上內嵌於進度條左側。
  - **[Feature] 鍵盤導覽** — `window.keydown` 事件監聽：`ArrowRight`/`ArrowDown` 下一張、`ArrowLeft`/`ArrowUp` 上一張、`Space` 暫停/播放。在 `onMounted` 掛載、`onBeforeUnmount` 移除。
  - **[Bug Fix] `component_explain` 永遠顯示 `short_desc`** — AI 為解說投影片撰寫的 `summary`（經 `resolveSceneFromDisplayPlan` 映射為 `subtitle`）被忽略，canvas 永遠顯示資料庫的 `short_desc`。修正：`short_desc` 段落改為 `v-if="!slide.subtitle"`，只在 AI 未提供說明時才顯示通用描述。
  - **[Bug Fix] industry 主題背景色丟失** — `.presentation-canvas.industry-*` 的 `background:` 屬性覆蓋了 `.presentation-canvas` 的 `background: #020617`，導致這些主題下畫面背景變成白色（只有淡淡的 radial-gradient）。修正：各 industry 主題的 `background` 最後加入 `#020617` 作為 base color。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `currentSlideDurationMs` computed 依賴 `slides` 與 `activeIndex`，當投影片切換後自動計算下一張的持續時間。`setupTimer` 的遞迴調用鏈：timeout 到期 → `nextSlide()` → `setupTimer()`，確保每張投影片使用自己的 `durationSec`。
  - 手動導覽（`prevSlide`/`nextSlide`/`jumpTo` 帶 `resetAutoplay: true`）直接調用 `setupTimer()`，清除舊 timeout 並以新 active slide 的 duration 重新計時，行為一致。
  - `clearTimer` 從 `clearInterval` 改為 `clearTimeout`，語義正確。
  - industry theme 的 `background` shorthand 最後以純色結尾是 CSS 合法語法（等同 `background-color`），不影響前面的 `radial-gradient` 層。

- verification:
  - `get_errors`：aiStudioStore.js 與 AIStudioPresentationCanvas.vue 均無錯誤
  - 邏輯驗證：`setTimeout` + 遞迴 `setupTimer()` 的計時鏈，在 `clearTimer()` 後不再觸發

- impact-risk:
  - `setTimeout` 遞迴：在極端情況下（slides 動態清空），`nextSlide()` 返回後 `setupTimer()` 仍會被調用一次。已有 `if (!enabled || !isPlaying.value || slides.value.length <= 1) return;` 保護，不會形成無限迴圈。
  - 鍵盤事件為全域監聽，若頁面其他 input 使用 Space 或箭頭鍵可能衝突。但目前 AI Studio 的 input 有自己的 `@keydown` 處理，且 Space 在非 focus 狀態下不影響輸入框。

- regression-test:
  - 測試 hero 投影片設定 `duration_sec: 8` → 確認 8 秒後自動切換（非 10 秒）
  - 測試 `bar` chart_type → 確認投影片顯示長條圖而非預設圖表
  - 按空白鍵 → 確認進度條暫停/繼續
  - 按 ← → → 確認手動導覽並重置計時

- traceability:
  - 接續 user-added/log/2026-05-02/1200-ai-studio-deep-upgrade.md

- next-actions:
  - 建議：`AIStudioView.vue` 的 `watch(lastBotMessage)` 自動切換至 `presentation` 模式的邏輯，考慮僅在 `displayPlan` 存在時才觸發，避免純問答也觸發場景切換
