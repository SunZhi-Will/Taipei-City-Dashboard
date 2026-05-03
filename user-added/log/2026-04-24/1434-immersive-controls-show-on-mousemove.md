# 全螢幕控制項滑鼠移動顯示修正 / Immersive Controls Show-on-Mousemove Fix

## 2026-04-24 14:34

- objective:
  - 全螢幕時不顯示「輪播展示」字樣。
  - 全螢幕時縮小按鈕、左右換頁按鈕預設隱藏，僅在滑鼠移動時顯示。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 在 `AIStudioView` 新增全螢幕 overlay 顯示計時器，滑鼠移動顯示 1.5 秒後自動隱藏。
  - 在全螢幕且 `selectedMode === presentation` 時，隱藏 `immersive-badge`（不顯示「輪播展示」）。
  - 在 `AIStudioPresentationCanvas` 新增控制層顯示計時器，滑鼠移動才顯示左右換頁與 dots。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - AIStudioView.vue
    - 新增 `immersiveUiVisible`、`immersiveUiTimer`。
    - 新增 `handleImmersiveMouseMove()` 與 `clearImmersiveUiTimer()`。
    - `aistudio-canvas` 綁定 `@mousemove`。
    - `immersive-overlay` 新增 `--visible` class 控制透明度。
    - `immersive-badge` 加條件：`selectedMode !== 'presentation'`。
    - 傳入 `:is-immersive="isImmersive"` 至 `AIStudioPresentationCanvas`。
  - AIStudioPresentationCanvas.vue
    - 新增 prop `isImmersive`。
    - 新增 `controlsVisible`、`controlsTimer`。
    - 新增 `handlePointerActivity()` / `clearControlsTimer()`。
    - root 綁定 `@mousemove` 觸發控制項顯示。
    - `controls-layer` 加入 `controls-layer--hidden` class，在隱藏時 opacity=0 並關閉 pointer-events。

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 僅新增輕量 timeout 事件，成本低。

- impact-risk:
  - 低風險：行為僅影響全螢幕顯示狀態。

- regression-test:
  - 全螢幕 presentation：預設看不到「輪播展示」、縮小按鈕與左右換頁按鈕。
  - 滑鼠移動時顯示控制項，停止移動約 1.5 秒後隱藏。
  - 非全螢幕模式控制項顯示行為維持原樣。

- traceability:
  - N/A

- next-actions:
  - P1: 若需更平滑，可改成「靠近右上角時只顯示縮小按鈕、靠近左右邊緣時顯示換頁鍵」的分區顯示策略。