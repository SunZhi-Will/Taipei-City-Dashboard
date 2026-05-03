# 修正切換面板 icon/樣式與公共儀表板顯示 / Fix Mobile Switcher Icon, Style, and Public Dashboard Visibility

## 2026-04-24 14:58

- objective:
  - 修正 mobile switcher 的 icon 與左側導覽不一致、視覺樣式不一致，以及公共儀表板不易辨識/未顯示感知問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/MobileDashboardSwitcher.vue

- summary:
  - 將 switcher 結構改為對齊 `MobileNavigation`/`SideBar`：加入分組標題 icon（`account_circle`、`public`）與 chevron 收合行為。
  - 使用 `SideBarTab` 渲染所有 dashboard 項目，確保項目 icon、文字、active 樣式與左側導覽同步。
  - 公共儀表板區塊改為明確標題 + 城市分組；若目前沒有可用公共儀表板，顯示 `尚無公共儀表板`。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 `collapsedStates` 與 `toggleCollapse`，提供與側欄一致的分組展開/收合互動。
  - 新增 `hasPublicDashboards` computed，避免公共區塊在空資料時看起來像「消失」。
  - 樣式改為側欄語彙：`h1/h2` 階層、`material-icons-round` chevron、`switcher-sub-no` 空狀態文案。
  - 保留 `SideBarTab` 的路由導航行為，點擊後仍會關閉 overlay。

- verification:
  - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/components/dialogs/MobileDashboardSwitcher.vue`：`No errors found`。
  - 目視邏輯檢查：
  - 私人/公共分組標題有 icon。
  - 公共儀表板固定存在分組標題；空資料時顯示提示文字。
  - 各 dashboard item 使用 `item.icon` 與 `SideBarTab` 樣式。

- performance-impact:
  - 僅模板與樣式調整，無新增 API 請求。
  - 收合動畫為輕量 CSS transition，對效能影響可忽略。

- impact-risk:
  - 低風險：影響範圍限定於 mobile switcher。
  - 與 `SideBarTab` 同步後，未來若全域 tab 樣式調整，switcher 會同步變動（符合本需求）。

- regression-test:
  - 在行動窄版打開切換面板，確認私人/公共分組 icon、字級與側欄語彙一致。
  - 確認公共儀表板有資料時能展開城市分組，無資料時顯示空狀態。
  - 點擊任何 tab 後，路由切換正常且 overlay 關閉。

- traceability:
  - related logs:
    - user-added/log/2026-04-24/1448-desktop-hide-mobile-switcher.md
    - user-added/log/2026-04-24/1450-mobile-switcher-sync-with-sidebar.md

- next-actions:
  - N/A
