# 輪播超高與文字下沉二次修正 / Secondary Fix for Presentation Overflow and Vertical Offset

## 2026-04-24 13:29

- objective:
  - 進一步修正輪播頁「內容仍偏高」問題。
  - 修正中間文字仍視覺偏下的體感。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TextUnitChart.vue

- summary:
  - 將分頁列改為絕對定位浮層，不再參與主內容高度計算。
  - 將組件卡片內容切成固定兩列（meta + chart 可用剩餘空間），避免高度疊加。
  - 壓縮 meta 與 chart 內邊距，並限制副標最多兩行，降低上方空間擠壓。
  - 微調 TextUnitChart 行距與區塊間距，減少文字視覺下沉感。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - AIStudioPresentationCanvas.vue
    - `.slide-content` 改為 `position: relative`，並調整 top padding。
    - `.slide-header` 改為 `position: absolute`（不占流布局）。
    - `.slide-chart-container` 由 flex 直排改為
      - `display: grid`
      - `grid-template-rows: auto minmax(0, 1fr)`
    - `.slide-component-meta` 減少 padding/gap。
    - `.slide-component-subtitle` 限制兩行省略。
    - `.chart-glass-base` 進一步收斂內距。
  - TextUnitChart.vue
    - `.TextUnitChart__content` 減少 padding，增加微小 gap。
    - `.TextUnitChart__value`、`.TextUnitChart__unit` 設定 `line-height: 1`。

- verification:
  - `get_errors`:
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/TextUnitChart.vue -> No errors found

- performance-impact:
  - 僅 CSS 布局調整，無額外運算與請求。

- impact-risk:
  - 低風險：集中於輪播展示樣式。
  - 若少數元件依賴較長副標，兩行限制可能截斷，已採省略顯示避免破版。

- regression-test:
  - 驗證輪播 component slide 不再超高裁切。
  - 驗證 TextUnitChart 文字區塊置中體感。
  - 驗證其他圖型在同輪播容器仍可完整顯示。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍有個別圖型偏移，可對該圖型增加 presentation 專屬 `--compact` 樣式分支。