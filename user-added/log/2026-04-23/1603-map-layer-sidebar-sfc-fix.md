# 修復 MapLayerSidebar SFC 重複內容 / Fix MapLayerSidebar SFC Duplicate Content

## 2026-04-23 16:03

- objective:
  - 修復 MapLayerSidebar.vue 因檔案尾端重複拼接內容造成的 SFC 解析錯誤。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue

- summary:
  - 重建 MapLayerSidebar.vue 為單一乾淨版本，移除 style 區塊後被重複附加的第二份 script/template 內容。
  - 保留目前地圖側欄的收合邏輯與獨立圓形按鈕結構，避免修語法時回退互動行為。

- change-type:
  - Fixed

- technical-details:
  - 刪除已損壞的 SFC 檔案後，以乾淨版本重新建立完整的 script、template、style 區塊。
  - 保留 islandCollapsed 狀態同步、dashboard/component toggle 邏輯、以及 map-island-toggle 的獨立定位樣式。
  - 確認檔案結尾停在單一 </style>，不再有額外殘留內容。

- verification:
  - 執行檔案診斷檢查：get_errors(MapLayerSidebar.vue) -> No errors found。
  - 檢查檔案開頭與尾端內容，確認只有一組合法的 SFC 結構，且沒有第二份重複 script/template。

- performance-impact:
  - N/A

- impact-risk:
  - 影響範圍限於地圖頁左側圖層側欄元件。
  - 若先前未保存的臨時版面調整只存在於損壞檔案殘片中，該殘片已被清除；目前保留的是可編譯且可維護的版本。

- regression-test:
  - 開啟 mapview 頁面，確認側欄可正常展開與收合。
  - 確認收合按鈕不被裁切，並且切換私人/公共儀表板與圖層勾選仍可操作。

- traceability:
  - N/A

- next-actions:
  - 若使用者仍需微調收合按鈕位置或側欄動畫，再基於目前乾淨版本做局部樣式調整。
