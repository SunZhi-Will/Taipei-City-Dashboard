# 公共儀表板下拉間距調整 / Public Dashboard Dropdown Spacing Adjustment

## 2026-04-23 16:16

- objective:
  - 調整地圖側欄中「公共儀表板」標題與其下方城市下拉選單之間距，提升視覺可讀性與操作辨識。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 在城市下拉選單樣式 `.map-city-select` 新增 `margin-top: 6px`。
  - 讓「公共儀表板」標題與下方下拉 UI 有適當留白，避免元件過度貼齊。

- change-type:
  - Changed

- technical-details:
  - 修改位置為 scoped SCSS 區塊中的 `.map-city-select`。
  - 既有 `margin-bottom: 8px` 維持不變，僅新增上方間距，不影響資料流、事件綁定與折疊邏輯。

- verification:
  - 以 VS Code 診斷檢查檔案錯誤：`get_errors` 顯示 No errors found。
  - 手動檢查樣式差異：確認 `.map-city-select` 已包含 `margin-top: 6px`。

- performance-impact:
  - 僅 CSS 單屬性調整，無可感知效能影響。
  - 不新增渲染計算負擔，layout 變更範圍侷限於該側欄區塊。

- impact-risk:
  - 低風險；可能連帶影響同元件其他使用 `.map-city-select` 的下拉區塊間距（屬一致性調整）。
  - 不影響 API、狀態管理、地圖圖層同步邏輯。

- regression-test:
  - 驗證「私人儀表板／我的最愛／公共儀表板」折疊與展開後的間距一致性。
  - 驗證桌機與行動版側欄在不同寬度下仍無重疊或裁切。

- traceability:
  - N/A

- next-actions:
  - 若需要僅限「公共儀表板」生效，可改為新增專用 class 以避免全域套用 `.map-city-select`。
