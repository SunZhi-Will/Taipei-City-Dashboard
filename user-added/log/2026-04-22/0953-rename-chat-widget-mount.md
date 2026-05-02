# 聊天掛載元件命名收斂 / Rename Chat Mount Component

## 2026-04-22 09:53

- objective:
  - 將聊天掛載元件名稱改為更中性的 ChatWidgetMount，降低歷史命名 AIChatHub 造成的理解負擔。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/AIChatHubWidgetMount.vue (renamed)
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetMount.vue
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 將 AIChatHubWidgetMount.vue 重新命名為 ChatWidgetMount.vue。
  - App.vue 同步調整 import 與 template 元件標籤。
  - 功能行為不變，僅進行命名與引用一致性整理。

- change-type:
  - Changed

- technical-details:
  - 檔案重命名使用 Rename-Item 執行。
  - App.vue:
    - import ChatWidgetMount from ./components/chat/ChatWidgetMount.vue
    - template 使用 ChatWidgetMount v-if=shouldShowChatLauncher

- verification:
  - Problems 檢查結果:
    - Taipei-City-Dashboard-FE/src/App.vue: No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetMount.vue: No errors found

- performance-impact:
  - 無效能影響（命名層調整）。

- impact-risk:
  - 低風險；僅路徑與符號名稱變更，且已同步更新引用。

- regression-test:
  - 進入 dashboard/mapview 檢查右下角聊天仍可顯示與開啟。

- traceability:
  - related-log: user-added/log/2026-04-22/0946-rewrite-chat-widget-mount-to-vue.md

- next-actions:
  - N/A
