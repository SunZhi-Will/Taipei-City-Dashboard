# 控制列改為預設精簡並可展開放大 / Default Compact Controls with Expand-to-Enlarge Toggle

## 2026-05-03 05:54

- objective:
  - 回應使用者反饋「按鈕太大、UI 變醜」，將控制元件恢復為預設精簡尺寸。
  - 新增可切換的展開按鈕，讓使用者需要時才放大控制列。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

- summary:
  - 調整 DashboardComponent 控制列按鈕與城市下拉為較小預設尺寸，減少壓迫感。
  - 在 AnimatedColumnChart 新增「展開/縮小」按鈕（open_in_full / close_fullscreen）。
  - 預設維持精簡版控制列；按下展開按鈕後才套用放大樣式（按鈕、滑桿、月份字級同步放大）。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - DashboardComponent:
    - `.dashboardcomponent-control-group-button`：`padding`、`min-height`、`font-size`、`font-weight` 下修為精簡版。
    - `.selectBtn`：`padding`、`min-height`、`font-size` 下修，維持可讀性但避免過大。
  - AnimatedColumnChart:
    - 新增 `controlsExpanded` 狀態控制展開/縮小。
    - 新增 `animcol-zoombtn` 展開按鈕。
    - `.animcol-controls` 預設使用 compact 尺寸。
    - 新增 `.animcol-controls-expanded`，在展開時放大 `play`/`zoom` 按鈕、slider 軌道與 thumb、月份字級。

- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue -> No errors found
  - 靜態檢查：
    - 展開按鈕 title 與 icon 狀態正確切換。
    - 預設樣式為 compact，僅在 `animcol-controls-expanded` 套用放大樣式。

- performance-impact:
  - 僅增加一個本地 UI state 與少量 CSS class 切換，效能影響可忽略。

- impact-risk:
  - 若某些使用者偏好一進頁就大尺寸，現在需手動按一次展開。
  - 展開狀態目前不持久化；重整後會回到 compact（屬預期）。

- regression-test:
  - 驗證動態長條圖控制列預設為較小尺寸。
  - 點擊展開按鈕後，控制列大小明顯放大；再次點擊可縮回。
  - 驗證播放、拖曳 slider、切換圖表功能不受影響。

- traceability:
  - Related user feedback: 「按鈕太大；希望有展開按鈕可放大」
  - commit: N/A
  - PR: N/A

- next-actions:
  - 若需要，可再加「記住上次展開狀態」到 localStorage，讓偏好跨重整保留。
