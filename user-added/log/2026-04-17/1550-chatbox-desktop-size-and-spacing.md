# 調整聊天視窗桌機尺寸與底部間距 / Adjust Chatbox Desktop Size and Bottom Spacing

## 2026-04-17 15:50

- objective:
  - 套用指定聊天視窗樣式：`width: 400px; height: 500px; margin-bottom: 1.5rem;`。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue

- summary:
  - 將桌機版 `.chatbox` 的底部間距從 `35px` 改為 `1.5rem`。
  - `width: 400px` 與 `height: 500px` 已為既有設定，維持不變。

- change-type:
  - Changed

- technical-details:
  - style:
    - `.chatbox`：`margin-bottom: 35px` → `margin-bottom: 1.5rem`

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found

- performance-impact:
  - 無效能影響，純 CSS 版面調整。

- impact-risk:
  - 低風險。
  - 僅影響桌機版聊天視窗與底部距離。

- regression-test:
  - 驗證桌機版聊天視窗尺寸為 400x500。
  - 驗證聊天視窗與底部距離為 1.5rem。
  - 驗證手機版 media query 行為維持不變。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1527-chatbox-reduce-bottom-side-spacing.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - N/A
