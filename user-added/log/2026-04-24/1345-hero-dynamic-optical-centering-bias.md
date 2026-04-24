# Hero 動態視覺置中偏壓修正 / Hero Dynamic Optical Centering Bias Fix

## 2026-04-24 13:45

- objective:
  - 針對使用者回報「hero 仍偏下」進行更強、可跨螢幕高度生效的視覺置中修正。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - hero 主區改為 grid 置中，避免 flex 在不同內容高度下產生體感偏移。
  - 增加動態上移偏壓（`clamp`），讓 1080p / 2K 都維持較一致的視覺中心。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `.slide-main--hero`
    - `display: grid; place-items: center;`
    - 新增底部偏壓 `padding-bottom: clamp(28px, 5vh, 56px)`
  - `.slide-info--hero`
    - `transform: translateY(clamp(-18px, -3.6vh, -42px))`

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 純 CSS 調整，無運算或網路成本影響。

- impact-risk:
  - 低風險，僅影響 hero / component_explain 視覺定位。

- regression-test:
  - 驗證 hero 第一頁標題與副標在視覺中線上方，無下沉感。
  - 驗證 component slide 不受影響，圖表區仍完整填滿。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍偏，可再把偏壓參數外部化為 CSS 變數，依場景（教育/交通/長照）分別微調。