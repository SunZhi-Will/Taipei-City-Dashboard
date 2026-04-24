# 行動切換面板與左側導覽同步 / Sync Mobile Switcher with Sidebar Content and Style

## 2026-04-24 14:50

- objective:
  - 讓 mobile dashboard switcher 的內容、文字、icon 與左側導覽列保持一致，避免兩邊顯示規則不一致。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/MobileDashboardSwitcher.vue

- summary:
  - `MobileDashboardSwitcher` 改為復用 `SideBarTab` 元件，與左側 `SideBar` 使用相同的 tab 呈現邏輯。
  - 分組文字與資料來源改為對齊左側導覽：私人儀表板（收藏組件 + 個人儀表板）、公共儀表板（依城市分組）。
  - 列表項目 icon 改為直接使用各 dashboard 的 `item.icon`，不再寫死 `map` 或 `space_dashboard`。
  - 點選 tab 由 `SideBarTab` 導航，並在點擊後關閉 switcher overlay。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 移除 `MobileDashboardSwitcher.vue` 內自建 route push 邏輯，避免與 `SideBarTab` 路由規則分歧。
  - 新增 `personalDashboards` computed：與左側一致，排除 `icon === "favorite"` 的個人儀表板。
  - 新增 `authStore.token` 條件，僅登入時顯示私人儀表板區塊，與左側行為一致。
  - 樣式層新增 `:deep(.sidebartab)` 局部覆寫，讓 switcher 內 tab 寬度與間距符合 overlay 版面，同時保留左側同款文字/icon/active 視覺。

- verification:
  - 檔案診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/components/dialogs/MobileDashboardSwitcher.vue`，結果為 `No errors found`。
  - 內容對齊檢查：確認私人/公共分組、收藏組件、個人儀表板、城市儀表板均由與左側一致的資料來源渲染。

- performance-impact:
  - 元件重用為主，未新增 API 請求。
  - 移除手寫列表 item DOM 與路由處理，維持或微幅降低維護成本與行為分歧風險。

- impact-risk:
  - 低風險：改動範圍集中於 mobile switcher 對話框。
  - 已知邊界：`SideBarTab` 若未來做全域樣式調整，switcher 會同步受影響（本次需求即期望同步）。

- regression-test:
  - 行動窄版開啟 switcher，確認 icon 與左側導覽一致。
  - 確認「收藏組件」與「個人儀表板」在登入狀態下顯示規則與左側一致。
  - 點選任一 tab 後，路由切換正常且 switcher 自動關閉。

- traceability:
  - related log: user-added/log/2026-04-24/1448-desktop-hide-mobile-switcher.md
  - ticket/PR: N/A

- next-actions:
  - 建議補一個 UI snapshot 或 E2E case，鎖定 switcher 與 sidebar 項目一致性（P2）。
