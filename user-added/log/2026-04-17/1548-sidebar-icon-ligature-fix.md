# 側欄圖示文字化修正 / Sidebar Icon Ligature Rendering Fix

## 2026-04-17 15:48

- objective:
  - 修正側欄 `account_circle`、`public` 等 Material icon 在 UI 中顯示為文字而非圖示的問題。

- files:
  - Taipei-City-Dashboard-FE/src/main.js
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 在前端入口新增本地 `material-icons` round 字型 CSS 載入，避免僅依賴 Google Fonts 外網資源。
  - 在 SideBar scoped 樣式補齊 ligature 需要的字型屬性（含 `font-feature-settings: "liga"`），讓 icon 名稱能正確被字型替換為圖示。
  - 將重複的 `font-family` 設定收斂到共用規則，降低之後樣式重寫造成圖示失效的風險。

- change-type:
  - Fixed

- technical-details:
  - `src/main.js` 新增 `import "material-icons/iconfont/round.css";`，由 bundler 直接打包本地 `woff/woff2` 字型。
  - `SideBar.vue` 在 `.sidebar` 區塊新增共用 icon 規則，套用於 `.sidebar-icon`、`.sidebar-chevron`、新增按鈕與收合按鈕的 icon `span`。
  - 共用規則加入 ligature 及可讀性相關設定：`font-style/font-weight/line-height/text-rendering/font-feature-settings`。

- verification:
  - 問題診斷：使用全文檢索確認 `account_circle` 出現在 SideBar 模板且 `sidebar-icon` 僅有 `font-family` 無 `liga`。
  - 程式檢查：對修改檔案執行語法/型別診斷，結果為 No errors。
  - 檢查方式：
    - 搜尋：`sidebar-icon|account_circle|material-icons|material-symbols`
    - 診斷：VS Code 問題檢查（`src/main.js`, `src/components/utilities/bars/SideBar.vue`）

- performance-impact:
  - 本地載入 icon font 可降低外部字型 DNS/TLS 請求依賴，首屏穩定性提升。
  - 新增 CSS 規則僅影響少量 icon 節點，效能影響可忽略。

- impact-risk:
  - 風險低；變更集中於 icon 字型與樣式，不改變資料流或業務邏輯。
  - 若未安裝 `material-icons` 套件才會失敗；目前 lockfile 與 node_modules 已存在該套件。

- regression-test:
  - 驗證側欄展開/收合時圖示仍正常顯示。
  - 驗證新增儀表板按鈕與收合按鈕 icon 不回退為文字。
  - 驗證離線或無法連線 Google Fonts 時，icon 仍可顯示。

- traceability:
  - log: user-added/log/2026-04-17/1548-sidebar-icon-ligature-fix.md

- next-actions:
  - 建議將其他使用 ligature 的 `span`（例如 admin 頁）逐步統一到同一個 icon utility class，避免局部樣式重寫再度造成文字化。
