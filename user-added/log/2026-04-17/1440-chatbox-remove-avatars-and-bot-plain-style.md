# 移除頭像並改為 AI 純文字回應樣式 / Remove Avatars and Switch Bot Replies to Plain Text Style

## 2026-04-17 14:40

- objective:
  - 讓用戶與 AI 回應都不顯示大頭照。
  - 讓 AI 回應不再使用區塊邊框泡泡，改為類 Cursor 的純文字回應視覺。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 移除 bot/user 模板中的 avatar DOM。
  - 移除 `BotLogo`、`UserLogo` import。
  - 新增 bot 專用 `message--plain` 樣式，無邊框、無卡片底。
  - bot 回應改用 `message--plain`；user 回應維持既有泡泡（僅依需求改 AI 無區塊）。

- change-type:
  - Changed

- technical-details:
  - template:
    - bot: 移除 `<div class="avatar"><BotLogo /></div>`。
    - user: 移除 `<div class="avatar"><UserLogo /></div>`。
    - bot content: `class="message--bubble"` 改為 `class="message--plain"`。
  - style:
    - 刪除 avatar 相關布局影響，調整訊息列 `gap` 與 `width`。
    - `.user` 改為 `justify-content: flex-end`。
    - 新增 `.message--plain p`：白字、無邊框、無背景。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 小幅減少 DOM 節點與 SVG 載入，對效能為正向微幅改善。

- impact-risk:
  - 低風險，主要是聊天 UI 呈現變更。
  - bot 與 user 視覺差異仍保留（bot 純文字、user 泡泡），可讀性可接受。

- regression-test:
  - 驗證 bot/user 訊息皆無頭像顯示。
  - 驗證 bot 回應不再有邊框泡泡。
  - 驗證 user 泡泡、表格推薦區、按鈕區仍正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1434-chatbox-send-button-single-circle-style.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 若要完全一致的純文字風格，可再把 user 訊息泡泡也改成無邊框版本。
