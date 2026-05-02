# 側欄中文顯示修正 / Sidebar Unicode Text Fix

## 2026-04-22 10:56

- objective:
  - 修正左側導覽中誤顯示 `\uXXXX` 字串，恢復正常中文文案。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue
- summary:
  - 將模板中的 Unicode 跳脫字串改回實際中文文字（例如：公共儀表板、私人儀表板、我的最愛、新增）。
  - 將插值中的 escaped 中文字串改為直接中文，提升可讀性與一致性。
- change-type:
  - Fixed
- technical-details:
  - 受影響區塊為 `SideBar.vue` template 中多個 `sidebar-label` 文字節點與部分屬性字串。
  - 根因為先前 patch 使用 escaped Unicode 寫入 template 文本節點，導致瀏覽器直接渲染反斜線字元。
- verification:
  - `grep_search` 檢查 `SideBar.vue`：無 `\\u[0-9a-fA-F]{4}` 殘留。
  - `get_errors` 檢查 `SideBar.vue`：No errors found。
- performance-impact:
  - 無效能影響，僅文字常數修正。
- impact-risk:
  - 低風險；僅影響顯示文案，不改動業務邏輯。
- regression-test:
  - 驗證側欄展開/收合兩種模式下文字均為正常中文。
  - 驗證私人/公共群組標題與新增按鈕文案正常顯示。
- traceability:
  - log: user-added/log/2026-04-22/1056-sidebar-unicode-text-fix.md
  - ticket/PR/commit: N/A
- next-actions:
  - N/A
