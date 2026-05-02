# 側欄新增按鈕寬度溢出修正 / Sidebar Add Button Width Overflow Fix

## 2026-05-02 17:08

- objective:
  - 修正個人儀表板第三層「新增」按鈕超出側欄寬度的問題

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 將 `sidebar-add-item` 的寬度由 `width: 100%` 調整為 `width: calc(100% - 16px)`
  - 保留左右 `margin: 8px` 的視覺留白，避免總寬變成 `100% + 16px` 而溢出

- change-type:
  - Fixed

- technical-details:
  - 問題成因：`width: 100%` 搭配 `margin-left/right: 8px`，實際佔位超出父容器
  - 修正策略：以 `calc(100% - 16px)` 扣除左右 margin 總和，維持滿列視覺且不超界

- verification:
  - 透過診斷工具檢查 `SideBar.vue`：No errors found
  - 手動檢視重點：按鈕與第三層項目左、右邊界對齊，無水平溢出

- performance-impact:
  - 僅 CSS 樣式調整，無效能衝擊

- impact-risk:
  - 影響範圍限於左側導覽列「個人儀表板」區塊新增按鈕樣式
  - 不涉及資料流、API、狀態管理

- regression-test:
  - 展開左側導覽列並展開「個人儀表板」，確認新增按鈕不超界
  - 收合/展開側欄切換後，按鈕寬度與對齊維持正常
  - 不同螢幕寬度下確認無橫向捲軸或裁切

- traceability:
  - related log: user-added/log/2026-05-02/1613-sidebar-nav-icon-add-button-refactor.md

- next-actions:
  - N/A
