# 左導覽列標題字級放大 / Sidebar Title Font Size Increase

## 2026-04-17 16:08

- objective:
  - 改善左側導覽列「私人儀表板 / 公共儀表板」標題字體過小的可讀性問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 將 SideBar 一級標題（h1）字級從 `11px` 調整為 `14px`。
  - 僅調整左導覽列標題字級，不變動其他互動、資料流與佈局邏輯。

- change-type:
  - Changed

- technical-details:
  - 變更位置：`.sidebar h1` 樣式區塊。
  - before: `font-size: 11px;`
  - after: `font-size: 14px;`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，純字級樣式調整。

- impact-risk:
  - 低風險；變更範圍限定於左導覽列 h1 文案顯示。

- regression-test:
  - 驗證左側「私人儀表板 / 公共儀表板」標題字級已變大。
  - 驗證展開/收合與點擊折疊行為維持正常。

- traceability:
  - log: user-added/log/2026-04-17/1608-sidebar-title-font-size-increase.md

- next-actions:
  - 若你覺得還不夠大，可再升到 `15px` 或改成 `var(--font-ms)` 做全域一致化。
