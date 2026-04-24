# 桌機隱藏行動切換遮罩 / Hide Mobile Switcher Overlay on Desktop

## 2026-04-24 14:48

- objective:
  - 修正桌機版不應顯示 mobile dashboard switcher overlay 的問題，避免使用者在桌機誤觸發行動版 UI。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue

- summary:
  - 在導覽列切換函式 `toggleDropdown` 新增裝置條件防護，僅允許行動窄版裝置切換開關。
  - `MobileDashboardSwitcher` 元件改為僅在 `authStore.isMobileDevice && authStore.isNarrowDevice` 條件下渲染。
  - 以元件層級條件渲染避免桌機 DOM 出現 overlay 節點，而非僅用 CSS 隱藏。

- change-type:
  - Fixed

- technical-details:
  - 於 `NavBar.vue` 的 `toggleDropdown` 開頭加入 guard clause：非行動窄版時強制 `isDropdownOpen = false` 並 return。
  - 於 `MobileDashboardSwitcher` 宣告加上 `v-if="authStore.isMobileDevice && authStore.isNarrowDevice"`。
  - 維持既有 API 與事件介面（`:is-open`、`@close`）不變，降低回歸風險。

- verification:
  - 檔案診斷檢查：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue`，結果為 No errors found。
  - 程式碼檢查：確認 `MobileDashboardSwitcher` 僅在行動窄版條件成立時才會掛載。

- performance-impact:
  - 桌機版減少不必要元件掛載與 teleport overlay DOM 節點建立。
  - 預期記憶體與重繪負擔微幅下降（無破壞性變更）。

- impact-risk:
  - 影響範圍限於導覽列主題切換互動。
  - 若未來產品希望平板或桌機也使用該 overlay，需調整條件邏輯。

- regression-test:
  - 桌機寬度（>= 768）：點擊主題名稱不應出現 `mobile-switcher-overlay`。
  - 手機寬度（< 768）且行動裝置：點擊主題名稱應可開啟/關閉 switcher。
  - 切換 dashboard 後路由 query（index/city）應維持既有行為。

- traceability:
  - ticket/PR: N/A
  - related log: user-added/log/2026-04-24/1448-desktop-hide-mobile-switcher.md

- next-actions:
  - 建議補一個 E2E 測試，驗證桌機寬度下 overlay 不存在（優先級：P2）。
