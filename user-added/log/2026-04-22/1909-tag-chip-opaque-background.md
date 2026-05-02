# Tag 改為不透明背景 / Make Tag Chips Opaque

## 2026-04-22 19:09

- objective:
  - 依需求將聊天建議 Tag 的背景改為不透明，不再透出底層背景。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將 `.tag-chip` 背景由半透明 `rgba` 改為實色 `#2b3037`。
  - 將 hover 背景同步改為實色 `#363d47`，維持互動層次但不透明。

- change-type:
  - Changed

- technical-details:
  - 僅調整 Tag 顯示層樣式，不修改互動事件、捲動控制與資料流。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 搜尋確認 `.tag-chip` 已套用不透明背景色值。

- performance-impact:
  - 無效能影響，僅樣式數值變更。

- impact-risk:
  - 低風險；若主題色系日後調整，可能需再同步校正實色對比度。

- regression-test:
  - 檢查 Tag 在一般與 hover 狀態均為不透明。
  - 確認 Tag 點擊、左右捲動按鈕與輸入流程維持正常。

- traceability:
  - Related log: user-added/log/2026-04-22/1908-floating-tags-and-input-without-wrapper-background.md

- next-actions:
  - N/A