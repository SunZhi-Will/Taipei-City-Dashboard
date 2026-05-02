# 地圖卡片控制區疏壓與按鈕放大 / Map Panel Spacing Relief and Button Scaling

## 2026-05-03 05:52

- objective:
  - 改善「食品業者衛生稽查地圖」在 map open 狀態下控制列過於擁擠問題。
  - 放大互動按鈕（圖表切換、播放按鈕、滑桿控制點）以提升可點擊性與可讀性。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

- summary:
  - 調整主控制列為可換行布局，並增加控制項間距，避免 city select 與圖表切換按鈕互擠。
  - 放大圖表切換按鈕字級與高度，提升桌機與行動裝置可用性。
  - 增加 mapopen 元件高度與圖表區比例，讓 header/control/chart 的垂直空間分配更均衡。
  - 放大 AnimatedColumnChart 的播放按鈕、滑桿軌道、thumb 與月份字級，並補上窄螢幕換行規則。

- change-type:
  - Changed

- technical-details:
  - DashboardComponent:
    - `.dashboardcomponent-control` 新增 `flex-wrap`, `justify-content: space-between`, `gap`, 並調整 `padding`。
    - `.dashboardcomponent-control-group` 移除 `translateX(-15%)`，改為可換行與 `gap` 排版。
    - `.dashboardcomponent-control-group-button` 提升 `padding/min-height/font-size/font-weight`。
    - `.selectBtn` 提升 `padding/min-height/font-size`，新增手機版寬度適配。
    - `.mapopen` 高度由 `330px` 提升為 `390px`，並在手機版提高到 `430px`；對應調整 `&-chart` 高度比例。
  - AnimatedColumnChart:
    - `.animcol-controls` 增加 `padding/gap/min-height`。
    - `.animcol-playbtn` 由 `28x28` 提升至 `40x40`，icon 由 `18px` 提升至 `24px`。
    - `.animcol-slider` 軌道由 `6px` 提升至 `8px`，thumb 尺寸同步放大。
    - 新增 `@media (max-width: 760px)` 讓 controls 換行，slider 改為整列寬度。

- verification:
  - 使用 VS Code diagnostics 檢查兩個修改檔案：
    - `get_errors` on `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` → No errors found
    - `get_errors` on `Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue` → No errors found
  - 靜態檢查重點：
    - class selector 與現有 template 對應一致（`dashboardcomponent-control*`, `animcol-*`）。
    - 手機 breakpoint (`max-width: 760px`) 與現有檔案慣用斷點一致。

- performance-impact:
  - 純 CSS 調整，無新增 API 呼叫或資料計算。
  - 預期渲染效能影響可忽略，僅增加少量 style 規則。

- impact-risk:
  - 風險：控制列放大後，在極小高度容器可能擠壓圖表可視高度。
  - 緩解：已同步提高 mapopen 高度與圖表比例，並在手機版加入換行規則避免重疊。

- regression-test:
  - 驗證 map open 狀態下 city select 與圖表切換按鈕是否無重疊。
  - 驗證 AnimatedColumnChart 播放按鈕與 slider 在桌機/手機可點擊性。
  - 驗證切換「圓餅圖 / 動態長條圖」後控制列不跳位。
  - 驗證其他 dashboard mode（`half`, `large`, `focus`）未受排版副作用影響。

- traceability:
  - Related user feedback:「UI 太擠，希望可放大按鈕」
  - commit: N/A
  - PR: N/A

- next-actions:
  - 若需要更大操作區，可再提供「大字版」參數（例如 `compact`/`comfortable`）做使用者可切換密度。
