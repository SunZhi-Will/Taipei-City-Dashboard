# Hero 首頁視覺中心修正 / Hero Slide Optical Centering Fix

## 2026-04-24 13:31

- objective:
  - 修正 Hero 首頁文字區塊仍偏下的視覺問題。
  - 針對 hero 與 component_explain 套用獨立版型，避免沿用 component 排版造成位移。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 新增 `slide-content--hero`，給 hero 頁專屬 padding。
  - `slide-main--hero` 增加 `align-items: center`，確保主內容在交叉軸也置中。
  - `slide-info--hero` 加入光學上移 `transform: translateY(-16px)`，修正使用者體感偏下。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - Template class binding:
    - 新增 `slide-content--hero` 條件：`slide.type === 'hero' || slide.type === 'component_explain'`。
  - CSS:
    - `.slide-content--hero { padding: 10px 16px 14px; }`
    - `.slide-main--hero { justify-content: center; align-items: center; }`
    - `.slide-info--hero { transform: translateY(-16px); }`

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 純樣式調整，無額外運算與 API 影響。

- impact-risk:
  - 低風險：僅影響 hero / component_explain 的視覺布局。

- regression-test:
  - 驗證第一頁 hero 文字塊在視覺上回到中線。
  - 驗證 component slide 不受影響，仍維持先前高度修正。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍需更精準，可依螢幕高度加入 `clamp` 動態位移（例如 `translateY(clamp(-10px, -1.8vh, -20px))`）。