# 清理未使用 Chat 腳本資產 / Remove Unused Chat Script Asset

## 2026-04-22 09:48

- objective:
  - 在已改為純 Vue 聊天架構後，移除未使用的 aichathub widget 腳本資產，避免維護混淆。

- files:
  - Taipei-City-Dashboard-FE/public/js/aichathub-widget-v2.js

- summary:
  - 刪除 Taipei-City-Dashboard-FE/public/js/aichathub-widget-v2.js。
  - 確認 public/js 目錄僅保留 mapbox-gl-rtl-text.js。

- change-type:
  - Removed

- technical-details:
  - 先以全文搜尋確認無任何程式碼再引用 aichathub-widget-v2.js。
  - 刪除後再檢查 public/js 目錄內容，確認檔案已不存在。

- verification:
  - 搜尋檢查：FE 程式內無外部引用此腳本。
  - 目錄檢查：Taipei-City-Dashboard-FE/public/js 僅剩 mapbox-gl-rtl-text.js。

- performance-impact:
  - 減少一個靜態資產，降低打包與部署雜訊。

- impact-risk:
  - 低風險；目前聊天功能已由 Vue 元件實作，不依賴該檔案。

- regression-test:
  - 進入 /dashboard、/mapview 檢查右下角聊天仍可開啟與發送訊息。

- traceability:
  - related-log: user-added/log/2026-04-22/0946-rewrite-chat-widget-mount-to-vue.md

- next-actions:
  - N/A
