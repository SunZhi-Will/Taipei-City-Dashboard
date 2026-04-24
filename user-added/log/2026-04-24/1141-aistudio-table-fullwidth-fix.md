# AI Studio 表格滿寬修正 / AI Studio Table Full-Width Fix

## 2026-04-24 11:41

- objective:
  - 修正 AI Studio 聊天中的 `ai-table` 未滿寬問題，讓表格可吃滿 bot 訊息可用寬度。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 將 bot 訊息外層容器由內容寬度策略改為滿寬策略。
  - 對 markdown 區塊與 `ai-table-wrapper` 增加明確 `width/min-width: 100%`，避免 shrink-to-fit。

- change-type:
  - Fixed

- technical-details:
  - `.acp__bot-block`：`width: 100%; max-width: 100%;`
  - `.acp__bot-markdown`：新增 `display: block; width: 100%;`
  - `.acp__bot-markdown .ai-table-wrapper`：新增 `display: block; width: 100%; min-width: 100%;`

- verification:
  - 使用 VS Code 問題檢查工具：
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue -> No errors found
  - 人工驗證重點：
    - `table.ai-table` 在 bot 區塊內可展開至可用寬度，不再貼內容寬。

- performance-impact:
  - 純 CSS 版面調整，無新增運算與 API。

- impact-risk:
  - 低風險：只影響 AI Studio 聊天 bot 訊息寬度策略。

- regression-test:
  - 驗證含表格與不含表格的 bot 訊息都可正常排版。
  - 驗證手機窄螢幕下仍可透過 wrapper 做水平捲動。

- traceability:
  - N/A

- next-actions:
  - 若你希望 bot 純文字不要滿版、只有表格滿版，可再做「僅 table 100%、文字維持 92%」的分離策略。