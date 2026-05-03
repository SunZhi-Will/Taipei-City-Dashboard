# 改寫聊天掛載為純 Vue 元件 / Rewrite Chat Mount to Pure Vue Component

## 2026-04-22 09:46

- objective:
  - 回應需求「不要直接用 aichathub-widget-v2.js」，將聊天掛載改為純 Vue 實作。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/AIChatHubWidgetMount.vue

- summary:
  - 移除 AIChatHubWidgetMount 內所有外部 script/style 動態載入與 window.initAIChatHubWidget 初始化邏輯。
  - 改為直接組合既有 Vue 聊天元件 ChatWidgetLauncher，完全不依賴 aichathub-widget-v2.js。

- change-type:
  - Changed

- technical-details:
  - AIChatHubWidgetMount.vue 現在僅保留：
    - script setup import ChatWidgetLauncher
    - template 渲染 <ChatWidgetLauncher />
  - 移除內容包含：
    - loadScript/loadStyle
    - getWidgetConfig
    - onMounted/onBeforeUnmount 的 window widget 生命週期處理

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/chat/AIChatHubWidgetMount.vue: No errors found
    - Taipei-City-Dashboard-FE/src/App.vue: No errors found

- performance-impact:
  - 移除第三方 CDN 腳本動態載入，降低初始化網路與執行成本。

- impact-risk:
  - 低風險：改為使用現有聊天流程（ChatWidgetLauncher + ChatBox + chatStore），不改動 API 契約。

- regression-test:
  - 進入 /dashboard、/mapview 檢查右下角聊天按鈕是否可開關。
  - 送出訊息檢查 chatStore 回覆流程正常。

- traceability:
  - related-log: user-added/log/2026-04-22/0945-apply-aichathub-widget-to-fe.md

- next-actions:
  - 若要完全清理舊資產，可再移除未使用的 public/js/aichathub-widget-v2.js。
