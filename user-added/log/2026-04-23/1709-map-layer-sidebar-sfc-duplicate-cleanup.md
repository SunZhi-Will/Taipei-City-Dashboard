# 清理 MapLayerSidebarContent 重複 SFC 結構 / Clean Duplicate SFC Structure in MapLayerSidebarContent

## 2026-04-23 17:09

- objective:
  - 修復 `MapLayerSidebarContent.vue` 因重複 `script/template/style` 區塊與破碎片段造成的 Vue SFC 編譯錯誤（line 686 附近）。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 刪除污染檔案並重建為單一合法 SFC（1 組 `script setup` + `template` + `style scoped`）。
  - 保留既有地圖側欄功能：私人/公共儀表板分組、城市切換、組件勾選同步、row 單一按鈕語意。
  - 排除第二份重複模板與破碎語法片段，恢復可編譯狀態。

- change-type:
  - Fixed

- technical-details:
  - `MapLayerSidebarContent.vue` 重新建立完整檔案內容，確保僅存在一組根級 SFC 區塊。
  - 保留 `handleDashboardRowClick` 行為：點擊 row 會切換儀表板並在未展開時自動展開。
  - 樣式維持 `.map-dashboard-row` 單一按鈕結構，避免巢狀按鈕語意問題。

- verification:
  - 使用 VS Code diagnostics (`get_errors`) 檢查：
    - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - 結果：No errors found。

- performance-impact:
  - 無顯著效能影響。
  - 主要為結構修復，不涉及計算流程改動。

- impact-risk:
  - 低風險：變更僅限單一元件檔案。
  - 若外部格式化工具再次錯誤拼接，可能重現同類問題。

- regression-test:
  - 進入 mapview，確認地圖側欄正常渲染。
  - 點擊私人/個人/公共儀表板 row 可正常切換並展開。
  - 勾選組件 checkbox 仍可同步地圖圖層。

- traceability:
  - Related logs:
  - user-added/log/2026-04-23/1704-地圖側欄整列單一按鈕語意修正-map-row-single-button.md

- next-actions:
  - P1: 若仍遇到同檔反覆被拼接，建議加入 pre-commit SFC 結構檢查。