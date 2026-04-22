# 僅在思考中顯示 AI 大頭照 / Show AI Avatar Only While Responding

## 2026-04-17 14:49

- objective:
  - 調整聊天視覺行為，AI 大頭照只在「思考中 / 回應中」顯示。
  - 一般 AI 訊息維持純文字顯示，不顯示大頭照。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 從 bot 訊息列移除常駐 avatar。
  - 在 `isResponding` 區塊加入 avatar 與文字，讓頭像只在回應等待狀態出現。
  - 保持使用者訊息無頭像、AI 訊息無泡泡邊框的既有設計。

- change-type:
  - Changed

- technical-details:
  - template:
    - 移除 `.bot` 內的 avatar 節點。
    - 在 `.responding-state` 內新增 `<div class="avatar"><BotLogo /></div>`。
  - style:
    - 移除 `.bot .avatar` 專屬樣式。
    - 新增 `.responding-state` 的水平排列與 `.avatar` 尺寸/對齊設定。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 僅在 `isResponding` 時增加一個小型圖示節點，效能影響可忽略。

- impact-risk:
  - 低風險，僅 UI 呈現條件調整。
  - 若未來改動回應狀態文案，需確認 avatar 仍綁定 `isResponding` 條件。

- regression-test:
  - 當 `isResponding = true` 時，顯示 AI 頭像與「小幫手回應中...」。
  - 當 `isResponding = false` 時，不顯示該頭像。
  - 既有 bot 歷史訊息不顯示頭像，user 訊息不顯示頭像。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1446-chatbox-enable-bot-avatar-only.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
