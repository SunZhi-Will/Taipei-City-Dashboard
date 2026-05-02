# 儀表板多格子版型與高度分級調整 / Dashboard Multi-Tile Layout and Height Tiering

## 2026-05-03 03:11

- objective:
  - 改善儀表板卡片同尺寸造成的內容擁擠與卡內垂直捲動問題。
  - 導入多格子布局，支援不同卡片寬高跨度（如 2x2、1x3），提升圖表可讀性。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 在 dashboard 主頁改為 tile-based CSS Grid，新增 `grid-auto-flow: dense` 與 `grid-auto-rows`，讓卡片可跨欄跨列排列。
  - 在卡片渲染層加入 `dashboard-tile` 外層容器與 `dashboard-tile--wide`、`dashboard-tile--tall` 兩種跨度類別。
  - 新增 `getTileClass` 規則，根據圖表型態（地圖/時間序列/熱圖等）與資料密度自動分配跨度。
  - 對 DashboardComponent 於此頁面套用高度填滿覆寫，避免固定高度壓縮內容。
  - 補齊手機斷點回退策略，行動裝置維持單欄與自然高度，避免版面破碎。

- change-type:
  - Changed

- technical-details:
  - 新增常數集合 `WIDE_CHART_TYPES`、`TALL_CHART_TYPES`，以圖表類型驅動寬版與高版卡片分類。
  - 新增 `getTileComponentStyle()`，將卡片容器高度固定為父容器 100%，並取消既有 max-height 限制。
  - 在 map-layers 與一般 dashboard 的 `v-for` 區塊新增外層 tile wrapper，維持既有交互事件不變。
  - 以 scoped `:deep()` 覆寫 `DashboardComponent` 在 dashboard 頁的內部高度計算，控制 chart/loading/error 區塊可用空間。
  - 保留 focus 模式不變，避免影響「展開內容區」既有流程。

- verification:
  - 執行 VS Code 診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`，結果 `No errors found`。
  - 靜態檢查模板綁定：確認 map-layers 與一般 dashboard 兩段 `v-for` 都已改為 tile wrapper 並維持原本事件處理。

- performance-impact:
  - 預期改善卡片內容可視高度，降低使用者在單卡內垂直捲動的頻率。
  - CSS Grid dense 佈局增加排版彈性，對 runtime 開銷極低，主要為瀏覽器排版階段調整。

- impact-risk:
  - 自動分類規則可能在少數儀表板出現非預期跨度，需視實際資料組合微調。
  - `:deep()` 覆寫依賴現有 class 命名，若 DashboardComponent 後續改名，需同步更新。
  - 已在手機斷點回退單欄，降低小螢幕排列風險。

- regression-test:
  - 驗證桌機寬度（>=1296）是否出現混合大小卡片，並確認無卡片重疊。
  - 驗證超寬螢幕（>=1800）是否能呈現跨欄卡片（接近 4x2 視覺）。
  - 驗證手機寬度（<=768）卡片是否回到單欄且可完整閱讀。
  - 驗證展開內容區（focus 模式）與收藏/刪除/切城市功能是否正常。

- traceability:
  - Related request: 使用者提出「深度分析 UIUX，改為多格子高度，避免圖表過高需滑動」。

- next-actions:
  - 若需完全可控的 2x2、4x2 指定布局，下一步可新增後端欄位（例如 `layout_w`, `layout_h`）並由前端直接吃配置。
