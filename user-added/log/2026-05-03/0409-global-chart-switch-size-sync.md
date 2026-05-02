# 全域圖型切換尺寸同步優化 / Global Chart-Switch Size Sync Enhancement

## 2026-05-03 04:09

- objective:
  - 讓所有可切換圖型的元件在切換後都同步更新卡片尺寸，避免再次出現卡內上下滑輪。
  - 修正 food safety 專屬 profile 中預設值阻斷動態規則的問題。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 調整 `getTileClass()`：以每張卡的 `activeChart` 作為優先判斷基準，讓多圖型卡片切換時可即時改變跨度。
  - 對多圖型卡片新增通用規則：
    - 切到寬圖型 -> `dashboard-tile--wide-tall`
    - 切到高密度長條型 -> `dashboard-tile--x-tall`
    - 其他圖型 -> default
  - 移除 food_safety profile 中多個空字串預設（`""`）項目，避免 profile 提前攔截通用動態規則。
  - 新增 `componentActiveCharts` 初始化 watcher，確保 dashboard 切換或資料更新後 cache 一致。
  - 為 `.dashboard-tile` 新增 transition，讓切換引發的版面更新更平滑。

- change-type:
  - Changed

- technical-details:
  - `DASHBOARD_LAYOUT_PROFILES` 僅保留必要覆寫（例如 `food_poisoning_trend`、`food_poisoning_place` 與特定 function 規則）。
  - `getTileClass()` 內改用：
    - `activeChart = componentActiveCharts[item.id] || firstType`
    - `hasWideActiveChart = WIDE_CHART_TYPES.has(activeChart)`
    - `hasTallActiveChart = TALL_CHART_TYPES.has(activeChart)`
  - 新增 `watch(() => contentStore.currentDashboard.components, ...)`：
    - 依每個 component 首圖型初始化 cache
    - 保留既有已切換過的 activeChart state
  - `.dashboard-tile` 新增 `transition: all 0.24s ease;`

- verification:
  - VS Code 診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`，結果 `No errors found`。
  - 靜態檢查：確認 profile 未定義項目會回退至通用 activeChart 動態規則。

- performance-impact:
  - 新增 watcher 與 class 計算成本低，僅在 dashboard components 或 chart 切換時更新。
  - 減少使用者在卡內滾動操作，提升閱讀效率。

- impact-risk:
  - 大量同時切換圖型時，grid 重新排版可能造成輕微 layout shift（已用 transition 緩和）。
  - 若未來新增圖型但未納入 `WIDE_CHART_TYPES` / `TALL_CHART_TYPES`，可能不會觸發預期跨度。

- regression-test:
  - 在多個可切換元件（Donut/Bar、Bar/Percent 等）切換圖型，確認 tile 尺寸會更新且不卡內滑輪。
  - 驗證 food_safety_tpe / food_safety_taipei 及一般 dashboard 都能生效。
  - 驗證手機斷點仍維持單欄策略。

- traceability:
  - Related request: 使用者要求「其他圖表切換也要大小變更」。

- next-actions:
  - 若要更進一步，可新增 per-dashboard 配置化 schema（後端欄位）管理圖型->跨度映射，取代前端硬編碼。
