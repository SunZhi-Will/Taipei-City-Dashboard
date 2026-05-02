# 套用 AIChatHub 右下角聊天元件到前端主站 / Apply AIChatHub Bottom-Right Chat Widget to FE

## 2026-04-22 09:45

- objective:
  - 將使用者指定的 widget-demo-clean Chat Bot 正式套用到 Taipei-City-Dashboard-FE。
  - 讓 dashboard/mapview 直接使用 AIChatHub widget，而非既有內建聊天 launcher。

- files:
  - Taipei-City-Dashboard-FE/public/js/aichathub-widget-v2.js
  - Taipei-City-Dashboard-FE/src/components/chat/AIChatHubWidgetMount.vue
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 複製使用者提供的 aichathub-widget-v2.js 至 FE public/js，作為正式靜態資源。
  - 新增 AIChatHubWidgetMount Vue 掛載元件：
    - 動態載入 marked、Chart.js、Leaflet（含 CSS）與 widget 腳本。
    - 呼叫 window.initAIChatHubWidget 初始化右下角聊天。
    - 支援 unmount 時 destroy，避免重複掛載殘留。
  - App.vue 將聊天元件切換為 AIChatHubWidgetMount，並沿用 shouldShowChatLauncher（dashboard/mapview）顯示條件。

- change-type:
  - Changed

- technical-details:
  - AIChatHubWidgetMount 透過 script id 去重載入第三方依賴，避免重複 append script。
  - widget config 支援環境變數：
    - VITE_CHAT_WIDGET_PROJECT_ID
    - VITE_CHAT_WIDGET_CHATBOT_ID
    - VITE_CHAT_WIDGET_BASE_URL
  - 若未提供環境變數，使用安全預設值（projectId/chatBotId: taipei-city-dashboard；baseUrl: window.location.origin）。
  - 使用 window.__aichathubWidgetInstance 防止熱重載或重複初始化造成多實例。

- verification:
  - 問題檢查（Problems）:
    - Taipei-City-Dashboard-FE/src/App.vue: No errors found
    - Taipei-City-Dashboard-FE/src/components/chat/AIChatHubWidgetMount.vue: No errors found
  - 靜態資源檢查:
    - Taipei-City-Dashboard-FE/public/js 目錄已存在 aichathub-widget-v2.js

- performance-impact:
  - 首次啟用會額外載入 3 個 CDN 套件（marked/Chart.js/Leaflet）與 widget 腳本。
  - 載入採懶初始化（僅在聊天元件掛載時觸發），對非目標路由影響有限。

- impact-risk:
  - 中低風險：依賴外部 CDN，若網路策略阻擋 CDN 可能影響圖表/地圖功能。
  - 既有舊聊天元件仍保留程式碼但不再在 App 使用，若需回退可快速切回。

- regression-test:
  - 進入 /dashboard 與 /mapview 檢查右下角 launcher 是否出現。
  - 點擊 launcher 開啟/關閉聊天視窗。
  - 送出訊息確認請求是否命中 baseUrl + /api/chat。
  - 驗證圖表/地圖回覆時依賴套件可正常渲染。

- traceability:
  - related-log: user-added/log/2026-04-22/0934-fe-chat-launcher-apply.md

- next-actions:
  - 若正式環境 API 非同源，請設定 VITE_CHAT_WIDGET_BASE_URL 與對應 chatBotId。
