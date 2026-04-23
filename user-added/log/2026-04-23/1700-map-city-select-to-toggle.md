# 城市切換改為左右 Toggle 按鈕 / Replace City Select Dropdown with Toggle Button

## 2026-04-23 17:00

- objective:
  - 將公共儀表板的城市選擇從 `<select>` 下拉改為左右切換的 toggle 按鈕，提升操作直覺性

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 移除 `.map-city-select` select 元素，改用 `.map-city-toggle` div 包含多個 `.map-city-toggle-btn` 按鈕
  - 當選中的城市與按鈕對應時，加上 `active` class 顯示高亮
  - 點擊按鈕直接設定 `selectedPublicCity` 的值
  - 只有 `publicCityOptions.length > 1` 時才顯示 toggle（維持單城市時不顯示的原邏輯）

- change-type:
  - Changed

- technical-details:
  - Template: `<select v-model>` → `<div class="map-city-toggle">` + `<button v-for>`
  - 樣式: 移除 `.map-city-select`，新增 `.map-city-toggle`（flex container）與 `.map-city-toggle-btn`（含 active/hover 狀態）
  - Vue 3 ref 在 template 中自動解包，`@click="selectedPublicCity = city"` 正確更新

- verification:
  - 檢查 [MapLayerSidebarContent.vue](Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue) 第 275-290 行確認 toggle markup 正確
  - 確認舊 `.map-city-select` 樣式已移除，新 `.map-city-toggle` / `.map-city-toggle-btn` 樣式已加入

- impact-risk:
  - 低風險；僅影響 MapLayerSidebarContent 公共儀表板城市切換 UI
  - 功能邏輯不變，只改 UI 呈現方式

- regression-test:
  - 驗證雙北模式下 toggle 兩個按鈕都可切換
  - 驗證單城市時 toggle 不顯示
  - 驗證切換後儀表板清單正確更新

- traceability:
  - N/A

- next-actions:
  - N/A
