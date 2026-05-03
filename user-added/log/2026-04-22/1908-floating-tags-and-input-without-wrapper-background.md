# 移除輸入區包覆背景並改為底部懸浮 / Remove Input Wrapper Background and Float Tags/Input at Bottom

## 2026-04-22 19:08

- objective:
  - 依需求移除輸入區共同包覆背景容器，讓 tags 與輸入框改為底部固定懸浮。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 移除 template 中的 `.input-area` 包覆層。
  - `tags-area` 與 `input-shell` 改為獨立、固定於聊天視窗底部的懸浮區塊。
  - 聊天主區增加底部留白，避免訊息被懸浮輸入區遮擋。
  - 去除原先輸入區整塊背景與上邊線視覺。

- change-type:
  - Changed

- technical-details:
  - `chat-widget` 增加 `position: relative`，供子元素做底部絕對定位。
  - `.tags-area` 以 `bottom` 錨定在輸入框上方，`.input-shell` 錨定在最下方。
  - 手機媒體查詢同步調整底部 offset 與 chat-area padding。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 確認 SCSS 結構大括號完整且可正常編譯。

- performance-impact:
  - 無效能影響，僅版面配置與樣式調整。

- impact-risk:
  - 懸浮布局會依視窗高度呈現；若未來再調整聊天高度，可能需要同步微調底部留白數值。

- regression-test:
  - 展開/縮小聊天視窗，確認 tags 與輸入框固定在底部且不出現包覆背景區。
  - 捲動聊天紀錄，確認訊息內容不被底部懸浮區塊遮擋。
  - 在手機寬度確認懸浮區塊位置與輸入交互正常。

- traceability:
  - Related log: user-added/log/2026-04-22/1904-related-indicator-click-area-text-only.md

- next-actions:
  - 若要更強化「完全無底板」感，可再把輸入框陰影強度降一級。