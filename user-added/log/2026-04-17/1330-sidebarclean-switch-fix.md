# 切換乾淨側欄元件修復編譯 / Switch to Clean Sidebar Component Fix

## 2026-04-17 13:30

- objective:
  - 在不使用終端指令下，立即排除 `SideBar.vue` 重複 `<script setup>` 造成的 Vite 編譯錯誤

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBarClean.vue
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 新增乾淨版 `SideBarClean.vue`，保留原有左側欄邏輯與圓球按鈕 UI。
  - 將 `App.vue` 的 `SideBar` import 切換到 `SideBarClean.vue`。
  - 透過切換引用，避免編譯流程再載入污染的 `SideBar.vue`。

- change-type:
  - Fixed

- technical-details:
  - `SideBarClean.vue` 包含單一 `<script setup>`、單一 `<template>`、單一 `<style>`。
  - 保留既有行為：
    - 左側欄展開/收起
    - 私人與公共儀表板折疊
    - 右側邊線外小圓球切換按鈕（`right: -18px`）

- verification:
  - `get_errors` 檢查：
    - `App.vue`: No errors found
    - `SideBarClean.vue`: No errors found

- performance-impact:
  - 無額外效能成本，僅元件檔案引用切換。

- impact-risk:
  - 低；若後續有其他地方直接引用 `SideBar.vue`，可再逐步替換。

- regression-test:
  - 檢查 `mapview`/`dashboard` 左側欄是否正常顯示。
  - 檢查展開/收起圓球按鈕是否在邊線外可點擊。

- traceability:
  - Related: user-added/log/2026-04-17/1323-sidebar-toggle-ball-outside-fix.md

- next-actions:
  - 若確認穩定，可安排後續清理/重建舊 `SideBar.vue` 以移除技術債。
