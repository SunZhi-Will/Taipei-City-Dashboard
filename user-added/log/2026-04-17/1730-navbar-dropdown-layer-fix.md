# 導覽列下拉選單層級修正 / Navbar Dropdown Layer Fix

## 2026-04-17 17:30

- objective:
  - 修正上方導覽列（用戶/資訊）展開選單被主內容區與側欄遮住的顯示問題。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue

- summary:
  - 在 `.navbar` 新增 `z-index: 30`，建立較高層級的 stacking context。
  - 在 `.navbar` 新增 `overflow: visible`，確保下拉選單向下展開時不被導覽列容器裁切。
  - 根因為側欄容器具有 `z-index: 15`，而導覽列下拉選單僅 `z-index: 10`，導致繪製層級被壓過。

- change-type:
  - Fixed

- technical-details:
  - `NavBar.vue` 的 `.navbar` 原本僅 `position: relative`，未明確提升整體層級。
  - 下拉選單 `ul` 使用 `position: absolute` 與 `z-index: 10`，在根層比較時低於 `SideBar/AdminSideBar` (`z-index: 15`)。
  - 將導覽列本體提高為 `z-index: 30` 後，整個導覽區（含絕對定位下拉）可穩定覆蓋內容區。

- verification:
  - 透過語法診斷確認修改檔案無錯誤：`get_errors` 檢查 `NavBar.vue` 回傳 No errors found。
  - 以樣式比對檢查層級：`NavBar.vue` 新增 `z-index: 30`，且 `SideBar.vue` / `AdminSideBar.vue` 仍為 `z-index: 15`。
  - 建議手動回歸：登入後展開右上角「資訊」與「用戶」下拉，確認在 `/dashboard` 與 `/mapview` 皆不被遮擋。

- performance-impact:
  - 無顯著效能影響；僅調整 CSS 層級與 overflow 呈現行為。

- impact-risk:
  - 低風險。可能影響導覽列與其他浮層的覆蓋順序。
  - 既有 `NotificationBar` 使用 `z-index: 100`，仍高於導覽列，預期不受影響。

- regression-test:
  - 驗證 `/dashboard`、`/mapview`、`/admin` 三種路徑下導覽列互動。
  - 驗證視窗寬度 > 750px（桌機）與臨界寬度附近的下拉行為。
  - 驗證 chat widget 與通知列開啟時，導覽列下拉仍可正確顯示。

- traceability:
  - Related analysis request: 上方導覽列展開內容被遮住（2026-04-17）

- next-actions:
  - 若後續新增其他固定/浮動列，統一建立全站 z-index token 表（例如 navbar=30, sidebar=15, dialog=50, notification=100）。
