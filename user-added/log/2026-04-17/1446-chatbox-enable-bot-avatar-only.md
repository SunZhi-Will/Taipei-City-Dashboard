# 僅恢復 AI 大頭照 / Re-enable Bot Avatar Only

## 2026-04-17 14:46

- objective:
  - 依需求讓 AI 回應顯示大頭照。
  - 使用者回應維持無頭像。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 新增 `BotLogo` import。
  - 在 bot 訊息區塊加回 avatar DOM。
  - 新增 bot avatar 專屬樣式（28x28）並維持 user 無 avatar。
  - AI 回應仍維持純文字樣式（無邊框泡泡），未回退為卡片樣式。

- change-type:
  - Changed

- technical-details:
  - script:
    - `import BotLogo from "../icons/BotLogo.vue";`
  - template:
    - 在 `.bot` 內加入 `<div class="avatar"><BotLogo /></div>`。
  - style:
    - 在 `&.bot` 下新增 `.avatar` 尺寸、對齊與 `svg` 自適應設定。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 僅增加 bot 訊息頭像節點，影響極小。

- impact-risk:
  - 低風險，僅聊天列表視覺調整。

- regression-test:
  - 驗證 bot 訊息有頭像。
  - 驗證 user 訊息無頭像。
  - 驗證 bot 純文字樣式（無泡泡邊框）維持正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1440-chatbox-remove-avatars-and-bot-plain-style.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
