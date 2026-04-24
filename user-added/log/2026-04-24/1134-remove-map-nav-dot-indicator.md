# 移除地圖導覽下方圓點標記 / Remove Bottom Dot Indicator from Map Navigation

## 2026-04-24 11:34

- objective:
  - 依需求移除地圖交叉比對頁導覽 active 狀態下方圓點，保留簡潔視覺。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 刪除地圖頁導覽 active 樣式中的 `::after` 指示點。
  - 保留 active 的背景高亮、字色、字重與內框效果，不影響目前頁面辨識。

- change-type:
  - Changed

- technical-details:
  - 自 `.map-nav-link.router-link-active, .map-nav-link.router-link-exact-active` 區塊移除 `&::after` 子規則。
  - 未調整 router-link 或路由邏輯，僅樣式微調。

- verification:
  - 使用 VS Code 診斷檢查：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/MapView.vue`，結果為 No errors found。
  - 檔案檢查：確認 active 樣式區塊已無 `::after` 定義。

- performance-impact:
  - CSS 規則減少，效能影響可忽略，無額外運算與渲染負擔。

- impact-risk:
  - 低風險：僅調整 scoped style，影響範圍限定在地圖頁導覽連結。
  - 主要風險為視覺辨識度下降，但仍保留高亮背景與字重強化。

- regression-test:
  - 開啟 `/mapview?index=ltc_care_tpe&city=taipei`，確認「地圖交叉比對」active 狀態不再顯示底部圓點。
  - 切換至 `/dashboard?...`、`/ai-studio?...`，確認 active 樣式仍可正常切換。

- traceability:
  - log: user-added/log/2026-04-24/1134-remove-map-nav-dot-indicator.md

- next-actions:
  - N/A
