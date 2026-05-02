# 地圖搜尋 AI 按鈕移入輸入框 / Move AI Toggle Inside Search Capsule

## 2026-04-24 16:06

- objective:
  - 將 AI 模式按鈕從外部區塊移到搜尋輸入框內，符合膠囊搜尋操作預期。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue

- summary:
  - 移除 quick-locations 區塊中的 AI 按鈕。
  - 在搜尋膠囊內新增 AI toggle 按鈕，位置為輸入欄右側、搜尋 icon 左側。
  - 保留 AI 模式啟用/停用與 active 狀態視覺。

- change-type:
  - Changed
  - Fixed

- technical-details:
  - Template:
    - 刪除 `.mapcontainer-quick-locations-ai-toggle` 按鈕。
    - 新增 `.mapcontainer-location-search-ai` 於 `<form class="mapcontainer-location-search">` 中。
  - Style:
    - 移除 `.mapcontainer-quick-locations-ai-toggle` 樣式。
    - 新增 `.mapcontainer-location-search-ai` 樣式與 `.is-active` 狀態樣式。

- verification:
  - VS Code 診斷檢查：
    - get_errors on `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue`
    - 結果：No errors found。

- performance-impact:
  - 無顯著效能影響（純 UI 位置與樣式調整）。

- impact-risk:
  - 低風險：僅影響按鈕位置與樣式，AI 模式邏輯不變。

- regression-test:
  - 展開搜尋膠囊後可看到 AI 按鈕位於輸入框內。
  - 點擊 AI 可切換 active 樣式，搜尋流程仍可正常定位。
  - Enter 與搜尋 icon 送出行為維持可用。

- traceability:
  - user-added/log/2026-04-24/1605-map-search-ai-mode.md

- next-actions:
  - N/A
