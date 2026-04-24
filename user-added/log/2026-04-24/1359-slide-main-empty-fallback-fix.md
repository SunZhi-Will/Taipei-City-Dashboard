# 輪播空白頁保底修正 / Blank Slide Fallback Fix

## 2026-04-24 13:59

- objective:
  - 修正輪播中出現 `slide-main` 全空白（四個 v-if 全不命中）的問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 新增未知投影片型別判斷，避免未定義 type 導致空白頁。
  - 新增 map 頁缺資料保底提示，避免只有 map 正常分支時才顯示內容。
  - 未知型別改用 hero 文字頁樣式呈現，保證使用者有可讀內容。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 helper:
    - `isUnknownSlideType(slide)`
  - class 調整：
    - `slide-content--hero`、`slide-main--hero` 擴充至未知型別也套用。
  - template 新增 fallback block:
    - `slide.type === 'map' && !getSlideComponent(...).dashboardConfig` 顯示提示卡
    - `isUnknownSlideType(slide)` 顯示文字頁（title/subtitle）

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found

- performance-impact:
  - 純條件渲染與樣式使用，無新增 API 請求。

- impact-risk:
  - 低風險：僅在原本會空白的頁面新增保底內容。

- regression-test:
  - 驗證尾頁（如 05/05）不再出現空白畫面。
  - 驗證已定義 type（hero/component/component_explain/map）顯示行為不變。

- traceability:
  - N/A

- next-actions:
  - P1: 可再加入 console warn（僅開發環境）提示未知 slide type 內容，便於上游 scene 生成修正。