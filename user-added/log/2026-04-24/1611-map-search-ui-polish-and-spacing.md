# 地圖搜尋 UI 美化與間距優化 / Polish Map Search UI and Spacing

## 2026-04-24 16:11

- objective:
  - 改善搜尋膠囊視覺質感，並解決輸入框內模式切換按鈕上下間距過近問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 調整搜尋膠囊尺寸、內距、陰影與邊框，提升整體觀感。
  - 放大「一般/AI」切換器高度與內距，拉開上下留白。
  - 微調搜尋 icon 按鈕尺寸與 hover 回饋，提升操作感。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `.mapcontainer-location-search`:
    - `height` 2.25rem -> 2.6rem
    - `padding` 0 6px 0 12px -> 0 8px 0 14px
    - `gap` 8px -> 10px
    - 背景改為深色漸層，並新增陰影與更清楚的邊框
  - `input`:
    - 字級略增至 0.84rem 並加入 line-height 1.25
  - `-mode`（一般/AI 切換器）:
    - `width` 5.2rem -> 5.6rem
    - `height` 1.9rem -> 2.2rem
    - `padding` 2px -> 3px
    - 滑塊 (`::before`) 尺寸與位置同步調整，加入漸層與陰影
  - `-action`（搜尋 icon）:
    - 尺寸 1.9rem -> 2.1rem
    - hover 增加輕微浮起效果
  - 手機斷點同步調整高度與尺寸，避免小螢幕擁擠。

- verification:
  - VS Code 診斷檢查：
    - get_errors on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 無顯著效能影響（僅樣式調整）。

- impact-risk:
  - 低風險：未改動搜尋邏輯與 API 流程。

- regression-test:
  - 搜尋膠囊展開後，一般/AI 切換器上下留白視覺正常。
  - 一般模式與 AI 模式切換正常，搜尋送出與 Enter 行為不受影響。
  - 手機寬度下檢查膠囊尺寸與按鈕可點擊性。

- traceability:
  - user-added/log/2026-04-24/1608-map-search-mode-segmented-toggle.md

- next-actions:
  - N/A
