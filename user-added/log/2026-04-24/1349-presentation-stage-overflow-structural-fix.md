# Presentation Stage 高度溢出結構修正 / Presentation Stage Overflow Structural Fix

## 2026-04-24 13:49

- objective:
  - 針對使用者指出 `presentation-stage` 超出高度問題進行結構性修復。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 將外層 stage 的 padding 移除，改放到每個 slide 內。
  - 加上 stage/track 的 `min-height: 0` 與 stage 的 `overflow: hidden`，防止 100% 高度鏈在 flex 內溢出。
  - 行動版 padding 同步改為 slide 層設定。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `.presentation-stage`
    - 移除 `padding: 10px 12px 18px`
    - 新增 `min-height: 0`
    - 新增 `overflow: hidden`
  - `.presentation-track`
    - 新增 `min-height: 0`
  - `.presentation-slide`
    - `padding: 0` -> `padding: 10px 12px 18px`
    - 保持 `box-sizing: border-box` 讓內距被包含在 slide 自身高度中
  - `@media (max-width: 900px)`
    - `.presentation-stage` 的 padding 規則改到 `.presentation-slide`

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 純 CSS 版面調整，無運算成本增量。

- impact-risk:
  - 低風險：主要影響輪播 slide 的可見區裁切與內距責任歸屬。

- regression-test:
  - 驗證 presentation hero/component slide 不再出現 stage 超高溢出。
  - 驗證輪播前後頁 3D 過場仍正常顯示。
  - 驗證 mobile (<900px) 內距與內容完整性。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍有偏差，下一步加 dev-only 高度量測標記（stage/track/slide 實際像素）做最終定位。