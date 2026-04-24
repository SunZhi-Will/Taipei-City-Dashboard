# 輪播進度重播與手動換頁重置修正 / Progress Replay and Manual Navigation Timer Reset Fix

## 2026-04-24 14:38

- objective:
  - 修正底部進度條只跑一次的問題。
  - 修正左右換頁/點選 dots 後 autoplay 節奏未重置的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 進度條新增 `progressRunKey`，每次重置都重建 progress DOM，確保 transition 可重播。
  - `resetProgress()` 改為雙層 `requestAnimationFrame` 啟動，避免同幀寫入導致動畫不觸發。
  - 手動切頁時（prev/next/jump）新增 `resetAutoplay` 選項，會重啟 timer，讓進度與輪播節奏一致。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增狀態：`progressRunKey`。
  - `nextSlide/prevSlide/jumpTo` 新增 options 參數，支援 `resetAutoplay`。
  - 模板中 prev/next/dot click 改為傳入 `{ resetAutoplay: true }`。
  - progress fill 增加 `:key="progressRunKey"`。
  - `resetProgress()`:
    - 先清空 `progressWidth/progressDuration`
    - `progressRunKey += 1`
    - 透過雙層 `requestAnimationFrame` 再設回目標 duration + 100%。

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 每次切頁重建進度條節點 1 次，成本極低。

- impact-risk:
  - 低風險：僅影響輪播進度與手動導航計時重置行為。

- regression-test:
  - 自動輪播：每張 slide 底部進度都會重新從 0 跑到 100。
  - 手動左右換頁：進度條立即重置並重新計時。
  - 點選 dots：進度條與 autoplay 週期重置且同步。

- traceability:
  - N/A

- next-actions:
  - P1: 若需可控節奏，可提供設定讓手動切頁時「是否重置 autoplay」可由 scene config 控制。