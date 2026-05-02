# RWD 底部導覽列新增登入按鈕並修正 AI Bot 重疊 / RWD Bottom Nav Login Button & AI Bot Overlap Fix

## 2026-05-02 09:47

- objective:
  - 手機 RWD 底部導覽列應始終顯示四個按鈕，包含登入入口
  - AI Bot 浮動按鈕不應與底部導覽列重疊

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue

- summary:
  - 在 `navItems` 中新增「登入」項目，type 為 `action`，`guestOnly: true`，點擊呼叫 `dialogStore.showDialog('login')`
  - 修改 `filteredNavItems` 邏輯：`authRequired` 僅登入後顯示，`guestOnly` 僅未登入時顯示
  - 底部導覽列 template 改為 `<template v-for>`，根據 `item.type` 動態渲染 `<router-link>` 或 `<button>`
  - 新增 `.app-bottom-nav-item--btn` CSS reset（去除 button 預設樣式）
  - 修改 `ChatWidgetLauncher.vue` 在 `@media (max-width: 768px)` 下的 `.chat-launcher-root` bottom 從 `max(16px, ...)` 改為 `calc(70px + max(16px, ...))`
  - chatbox 在手機展開時 bottom 從 `8px` 改為 `calc(70px + 8px)`，height 相應扣除 70px

- change-type:
  - Fixed

- technical-details:
  - 登入前：顯示 儀表板、地圖、AI、登入（4個）
  - 登入後：顯示 儀表板、地圖、組件、AI（4個）
  - AI Bot 浮動按鈕在手機底部偏移 70px（底部導覽列高度）+ safe area
  - 使用 CSS `calc()` 計算位置，避免 hard-code 重疊

- verification:
  - `get_errors` 檢查兩個修改檔案無 TypeScript/Vue 編譯錯誤
  - 邏輯審查：filteredNavItems 在 token 存在/不存在時各回傳 4 個項目

- impact-risk:
  - 僅影響 `isNarrowDevice` 為 true 的手機 RWD 視圖
  - 桌面版不受影響（底部導覽列有 `v-if="authStore.isNarrowDevice"` 條件）
  - AI Bot chatbox 高度在手機縮小 70px，內容空間略減但可接受

- regression-test:
  - 未登入手機視圖：底部導覽列顯示 4 個按鈕（儀表板、地圖、AI、登入）
  - 點擊登入按鈕：開啟登入 dialog
  - 登入後手機視圖：底部導覽列顯示 4 個按鈕（儀表板、地圖、組件、AI）
  - AI Bot 按鈕在儀表板/地圖頁面不與底部導覽列重疊
  - chatbox 展開時底部不被導覽列遮蔽

- traceability:
  - N/A

- next-actions:
  - N/A
