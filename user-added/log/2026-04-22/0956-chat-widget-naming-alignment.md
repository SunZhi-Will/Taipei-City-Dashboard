# 聊天元件命名一致性收斂 / Chat Widget Naming Alignment

## 2026-04-22 09:56

- objective:
  - 在完成 ChatWidget 架構遷移後，統一 App 內顯示條件命名，提升可讀性與維護一致性。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 將 computed 變數 `shouldShowChatLauncher` 更名為 `shouldShowChatWidget`。
  - 同步更新 template 中 `ChatWidgetMount` 的 v-if 條件引用。

- change-type:
  - Changed

- technical-details:
  - 僅命名調整，不更動顯示邏輯（仍為 dashboard/mapview 才顯示）。

- verification:
  - Problems 檢查：Taipei-City-Dashboard-FE/src/App.vue 無錯誤。
  - 掃描 FE src：無 AIChatHub/aichathub 舊命名殘留於業務碼。

- performance-impact:
  - 無。

- impact-risk:
  - 低風險，純命名重構。

- regression-test:
  - 進入 /dashboard、/mapview 檢查右下角聊天是否仍正常顯示。

- traceability:
  - related-log: user-added/log/2026-04-22/0953-rename-chat-widget-mount.md

- next-actions:
  - N/A
