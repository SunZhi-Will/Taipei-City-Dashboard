# 左側導覽列公共圖示根因修正 / Left Sidebar Public Icon Root Cause Fix

## 2026-04-17 16:06

- objective:
  - 針對左側導覽列「公共儀表板」icon 仍顯示文字的問題，做根因級修正。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 確認問題集中於左側導覽列 `h1` 樣式（`text-transform: uppercase`）影響 icon ligature。
  - 將 `account_circle` 與 `public` icon span 明確套用 `material-icons-round` class。
  - 在 `.sidebar-icon` 補齊完整 ligature 與字型渲染屬性，並強制 `text-transform: none`，避免再被父層 uppercase 破壞。

- change-type:
  - Fixed

- technical-details:
  - template:
    - `<span class="sidebar-icon">account_circle</span>` -> `<span class="sidebar-icon material-icons-round">account_circle</span>`
    - `<span class="sidebar-icon">public</span>` -> `<span class="sidebar-icon material-icons-round">public</span>`
  - style:
    - `.sidebar-icon` 新增：
      - `font-family: "Material Icons Round", var(--font-icon)`
      - `text-transform: none`
      - `font-feature-settings: "liga"`
      - `font-style/font-weight/line-height/letter-spacing`
      - smoothing 與 text-rendering 屬性

- verification:
  - 檔案內容檢查：已確認 `public` 與 `account_circle` 皆使用 `material-icons-round`。
  - 診斷檢查：
    - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue -> No errors found

- performance-impact:
  - 無顯著效能影響，屬字型渲染規則修正。

- impact-risk:
  - 低風險；僅影響左側導覽列標題 icon 呈現，不涉及資料與互動邏輯。

- regression-test:
  - 驗證未登入狀態（只顯示公共儀表板）時，`public` 仍顯示 icon。
  - 驗證登入狀態時，`account_circle` 與 `public` 均正常顯示。
  - 驗證側欄展開/收合後 icon 仍正常。

- traceability:
  - log: user-added/log/2026-04-17/1606-left-sidebar-public-icon-root-cause-fix.md

- next-actions:
  - 可將同套 icon utility 規則抽到共用 class，避免其他側欄/管理頁未來再出現同類退化。
