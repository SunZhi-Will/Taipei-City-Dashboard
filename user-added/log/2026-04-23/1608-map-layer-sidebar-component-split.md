# 拆分 MapLayerSidebar 元件 / Split MapLayerSidebar Component

## 2026-04-23 16:08

- objective:
  - 降低 MapLayerSidebar.vue 維護風險，並修正收合時因 v-if 移除內容導致的突兀消失感。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 將 MapLayerSidebar 拆成父元件外殼與子元件內容兩層。
  - 父元件只負責收合狀態、側欄位移與獨立圓形按鈕。
  - 子元件承接原本的 dashboard/component 展開、勾選與資料載入邏輯。

- change-type:
  - Changed

- technical-details:
  - 新增 MapLayerSidebarContent.vue，集中管理私人/公共儀表板清單、元件勾選、dashboard 詳細資料載入與地圖圖層同步邏輯。
  - 精簡 MapLayerSidebar.vue，只保留 isCollapsed 狀態同步、switch-dashboard 事件轉發與外層樣式。
  - 拿掉父元件中對內容區塊的 v-if，改用 transform 位移控制整個側欄，讓內容保留在 DOM 中，不再出現瞬間清空的視覺感。

- verification:
  - 執行檔案診斷檢查：get_errors(MapLayerSidebar.vue, MapLayerSidebarContent.vue) -> No errors found。
  - 檢查父元件模板，確認側欄內容由子元件承接，且父元件不再使用 v-if 移除內容。

- performance-impact:
  - N/A

- impact-risk:
  - 影響範圍限於 mapview 左側圖層側欄。
  - 因為邏輯搬移到新子元件，若未來再調整事件命名，需同步檢查父子元件 emit / import 關係。

- regression-test:
  - 開啟 mapview，確認側欄收合時為整塊位移而非內容瞬間消失。
  - 確認獨立圓形按鈕可正常切換展開/收合。
  - 確認私人與公共儀表板切換、元件勾選與細項展開仍可使用。

- traceability:
  - user-added/log/2026-04-23/1603-map-layer-sidebar-sfc-fix.md

- next-actions:
  - 若仍需更強的「推到外面」視覺感，可再微調 collapsed 狀態的 translateX 距離與透明度。
