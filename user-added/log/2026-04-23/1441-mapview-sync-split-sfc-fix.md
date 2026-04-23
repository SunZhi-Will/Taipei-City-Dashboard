# MapView 同步拆分與 SFC 結構修復 / MapView Sync Split and SFC Structure Fix

## 2026-04-23 14:41

- objective:
  - 依使用者要求「同步拆分程式」，將 MapView 清理為單一合法 SFC，排除重複模板與閉合錯誤。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 移除 MapView 中第一個 `</style>` 之後的殘留重複片段，保留單一 `<script setup> + <template> + <style>`。
  - 修復模板中 3 處損壞的 `<small>` 標籤，避免 `Element is missing end tag` 編譯錯誤。
  - 完成後檔案結構已一致，避免再次觸發 `only one <script setup>` 與 `Invalid end tag` 類錯誤。

- change-type:
  - Fixed

- technical-details:
  - 先以結構裁切方式移除重複 SFC 殘段，確保編譯器只看到一組根級區塊。
  - 再以精準 patch 修復三處壞掉標籤：`<small v-if="!hasMapConfig(component)">無地圖</small>`。
  - 最終結構檢查結果：
    - `<script setup>`: 1 個
    - `<template>`: 1 組
    - `<style scoped lang="scss">`: 1 組

- verification:
  - 結構檢查：
    - grep 檢查 `MapView.vue` 的 `<script setup>|<template>|</template>|<style scoped|</style>`，結果僅 5 個關鍵匹配（單一 SFC）。
  - 語法診斷：
    - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/MapView.vue`，結果 `No errors found`。
  - 執行期觀察：
    - `docker compose logs dashboard-fe --since 2m` 未出現新的 Vue SFC 編譯錯誤。

- performance-impact:
  - 無效能負擔增加。
  - 僅結構與語法修正，對 runtime 路徑無額外計算成本。

- impact-risk:
  - 低風險：調整集中於同一檔案的重複段落清理。
  - 已知風險：MapView 內部分中文文字目前存在歷史編碼異常（不影響編譯），後續可另開任務做文案編碼清理。

- regression-test:
  - 建議驗證：
    - 進入 `/mapview` 頁面確認可正常渲染。
    - 從聊天點擊「開啟地圖」確認仍可導頁並顯示地圖。
    - 勾選/取消圖層同步開關，確認地圖圖層正常開關。

- traceability:
  - Related logs:
    - user-added/log/2026-04-23/1407-地圖型組件聊天顯示修正-map-component-chat-render-fix.md
    - user-added/log/2026-04-23/1414-聊天地圖卡重複與自動啟動修正-chat-map-open-activation-fix.md
    - user-added/log/2026-04-23/1418-mapview-watch-brace-syntax-fix.md

- next-actions:
  - N/A
