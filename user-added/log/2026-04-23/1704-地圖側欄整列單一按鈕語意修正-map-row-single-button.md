# 地圖側欄整列單一按鈕語意修正 / Map Sidebar Row Single Button Semantics Fix

## 2026-04-23 17:04

- objective:
  - 修正地圖側欄 dashboard row 互動語意，將一列兩顆按鈕改為整列單一按鈕，符合使用者預期與無障礙語意。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 將 `map-dashboard-row` 從 `div + 兩顆 button` 重構為 `單一 button`，內容包含名稱與展開箭頭。
  - 點整列 row 的行為維持為「切換 dashboard + 若尚未展開則自動展開」。
  - 保留展開狀態顯示（`expand_more / expand_less`），並新增 row 的 focus-visible 樣式。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - 新增 `handleDashboardRowClick(scope, dashboard, city)` 取代舊的標題 click handler 命名，行為不變。
  - 更新私人最愛、個人儀表板、公共儀表板三處 row 模板，統一單一按鈕語意。
  - SCSS 由巢狀 `button` 結構改為 `.map-dashboard-row` + `.map-dashboard-name` + `.map-dashboard-arrow`。

- verification:
  - 使用 VS Code diagnostics (`get_errors`) 檢查：
    - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue
  - 結果：No errors found。
  - 靜態檢查模板：三個 dashboard list 均為單一 row button，無巢狀按鈕結構。

- performance-impact:
  - 無顯著效能影響。
  - 僅模板與樣式語意重構，無新增輪詢或重型運算。

- impact-risk:
  - 低風險：影響範圍限 map sidebar row 互動區塊。
  - 行為差異：移除右側箭頭獨立收合入口；目前整列點擊以「未展開則展開」為主，不主動收合。

- regression-test:
  - 點擊私人最愛 row 可切換並展開 components list。
  - 點擊個人儀表板 row 可切換並展開 components list。
  - 點擊公共儀表板 row 可切換並展開 components list。
  - 檢查鍵盤 tab 聚焦時 row 有可見 focus 樣式。

- traceability:
  - Related logs:
  - user-added/log/2026-04-23/1701-地圖側欄儀表板標題可展開-fix-dashboard-title-expand.md

- next-actions:
  - P1: 若需恢復「可收合」能力，可在單一按鈕上改為切換式（展開則收合），或加入獨立 icon span + `stopPropagation` 設計。