# 側欄圓球按鈕外移修正 / Sidebar Toggle Ball Outside Fix

## 2026-04-17 13:23

- objective:
  - 修正左側欄展開/收起圓球按鈕被區塊裁切的問題
  - 確保按鈕位於側欄最外層邊線外，且在展開/收起都可見可點擊

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/AdminSideBar.vue

- summary:
  - 將側欄內容改為內層容器捲動，按鈕保留在外層容器定位，避免被 scroll/overflow 裁切。
  - 將圓球按鈕水平外移至邊線外（right: -18px），並提高層級（z-index）以避免被相鄰主內容覆蓋。
  - 同步主側欄與管理側欄，使行為一致。

- change-type:
  - Fixed

- technical-details:
  - SideBar:
    - 新增 `.sidebar-content` 作為捲動層（`overflow-y: scroll`）。
    - 外層 `.sidebar` 改為 `overflow: visible`，並設定 `z-index: 15`。
    - `.sidebar-collapse-btnContainer` 位置固定在外側（`right: -18px`），按鈕層級提升為 `z-index: 20`。
    - 修復先前樣式片段誤插入 template/script 的污染，重建檔案結構。
  - AdminSideBar:
    - 新增 `.adminsidebar-content` 作為捲動層。
    - 外層 `.adminsidebar` 改為 `overflow: visible`。
    - `.adminsidebar-collapse-button` 外移至 `right: -18px`。

- verification:
  - 以語法診斷確認兩檔無錯誤：
    - `get_errors` on SideBar.vue => No errors found
    - `get_errors` on AdminSideBar.vue => No errors found
  - 以檔案內容檢查確認：
    - `SideBar.vue` 具有 `.sidebar-content` 並保留 `.sidebar-collapse-btnContainer-button`
    - `AdminSideBar.vue` 具有 `.adminsidebar-content`

- performance-impact:
  - 僅 CSS 定位與容器結構調整，對渲染效能影響可忽略。
  - 預期互動可見性提升，降低誤觸與找不到按鈕的操作成本。

- impact-risk:
  - 低風險：不涉及資料流與 API。
  - 可能邊界：極窄寬度下圓球與主內容距離較近，但仍可點擊。

- regression-test:
  - 測試主側欄展開/收起，確認圓球未被裁切。
  - 測試管理側欄展開/收起，確認圓球位置一致。
  - 測試頁面滾動時，圓球仍保持在側欄外邊線位置。

- traceability:
  - Related log: user-added/log/2026-04-17/1417-sidebar-ux-improvements-phase1.md

- next-actions:
  - 建議在 1366x768 與 1920x1080 檢視位置微調（可選：`right: -16px` 或 `-20px`）。
