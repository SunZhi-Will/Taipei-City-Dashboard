# 公共儀表板左側圖示渲染修正 / Public Dashboard Left Icon Rendering Fix

## 2026-04-17 16:00

- objective:
  - 修正側欄「公共儀表板」左側 `public` 圖示渲染不一致問題（有時顯示文字而非 icon）。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 將側欄兩個標題 icon（`account_circle`、`public`）改為明確套用 `material-icons-round` class。
  - 補齊 `.sidebar-icon` 的 ligature 必要字型屬性（`font-feature-settings: "liga"`、`text-transform: none` 等），避免被外層標題樣式影響。
  - 統一 icon 渲染行為，確保私人與公共區塊顯示一致。

- change-type:
  - Fixed

- technical-details:
  - template:
    - `<span class="sidebar-icon">...` 改為 `<span class="sidebar-icon material-icons-round" aria-hidden="true">...`。
  - style:
    - `.sidebar-icon` 新增 icon 字型渲染必要屬性：
      - `font-family: "Material Icons Round", var(--font-icon)`
      - `font-style/font-weight/line-height/letter-spacing`
      - `text-transform: none`
      - `font-feature-settings: "liga"`
      - smoothing 與 text-rendering 相關屬性

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue -> No errors found
  - 人工檢查：
    - `public` 與 `account_circle` 皆已套用 `material-icons-round` class。

- performance-impact:
  - 無顯著效能影響，僅 icon 字型渲染規則修正。

- impact-risk:
  - 低風險，變更範圍僅限側欄標題 icon 的模板與樣式。

- regression-test:
  - 展開與收合側欄時，確認「公共儀表板」左側 `public` 持續顯示為 icon。
  - 同時驗證「私人儀表板」`account_circle` 顯示正常。

- traceability:
  - log: user-added/log/2026-04-17/1600-sidebar-public-icon-render-fix.md

- next-actions:
  - 建議下一步將 `SideBarTab.vue` 的 icon span 也套用同一套 utility class，完全消除各處 icon 呈現差異風險。
