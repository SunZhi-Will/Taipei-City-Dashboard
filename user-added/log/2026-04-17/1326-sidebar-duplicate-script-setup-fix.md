# 修復 SideBar 重複 script setup / Fix Duplicate script setup in SideBar

## 2026-04-17 13:26

- objective:
  - 修復 Vite 編譯錯誤：`Single file component can contain only one <script setup> element`
  - 清理 `SideBar.vue` 尾端殘留重複內容，恢復單一 SFC 結構

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 刪除被污染的 `SideBar.vue`，以乾淨版本完整重建。
  - 保留先前 UI 需求：展開收起按鈕為右側邊線外的小圓球。
  - 移除檔尾重複段落，確保只有一組 `<script setup>/<template>/<style>`。

- change-type:
  - Fixed

- technical-details:
  - 造成錯誤的根因為檔案尾端存在第二段殘留內容，包含重複的 `<script setup>` 與模板片段。
  - 重建後 `SideBar.vue` 僅有一個 `<script setup>`，內容維持現有邏輯與樣式。

- verification:
  - 檢查 `<script setup>` 出現次數：1 次。
  - `get_errors` 檢查 `SideBar.vue`：No errors found。

- performance-impact:
  - 無額外效能成本。

- impact-risk:
  - 低風險，僅修復檔案結構與殘留內容。

- regression-test:
  - 建議檢查左側欄展開/收起功能是否正常。
  - 建議確認小圓球按鈕仍在右側邊線外可操作。

- traceability:
  - Related log: user-added/log/2026-04-17/1323-sidebar-toggle-ball-outside-fix.md

- next-actions:
  - 若 dev server 尚未刷新，重新整理頁面或重啟 FE 容器以確認錯誤消失。
