# 修正放大縮小後 X 捲軸與 Tag 箭頭問題 / Fix X Scrollbar and Tag Arrow Issues After Expand-Collapse

## 2026-04-22 18:53

- objective:
  - 修正聊天視窗放大再縮小後出現水平捲軸問題。
  - 修正放大縮小後建議 Tag 左右箭頭偶發消失問題。
  - 調整左右箭頭按鈕樣式為不透明顯示。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 在聊天主滾動區加上 `overflow-x: hidden`，避免切換尺寸後出現 X 向捲軸。
  - 新增 `refreshTagButtons`，在放大/縮小切換與視窗 resize 後重新計算左右箭頭顯示狀態。
  - 針對 Tag 左右箭頭按鈕改用實色背景、邊框與文字顏色，不再呈現半透明視覺。

- change-type:
  - Fixed

- technical-details:
  - `toggleExpand` 事件觸發後，先 `nextTick` 再延遲一次重算，涵蓋尺寸過渡動畫期間的寬度變化。
  - 在 `onMounted` 註冊 `window.resize` 監聽，`onBeforeUnmount` 解除，避免 stale 狀態造成箭頭誤判。
  - 箭頭按鈕維持原有 show/hide 邏輯（可捲動時顯示），僅調整其可見時的視覺不透明度與對比。

- verification:
  - 使用 VS Code diagnostics 檢查 Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue，結果為 No errors found。
  - 搜尋確認 `refreshTagButtons`、`onWindowResize`、`overflow-x: hidden` 已落在 ChatBox 對應區塊。

- performance-impact:
  - resize 事件新增輕量重算，僅做按鈕可見性判斷，效能影響可忽略。

- impact-risk:
  - 若未來聊天寬度動畫時間被調整，重算延遲可能需要同步微調。

- regression-test:
  - 開啟聊天後切換放大/縮小多次，確認無 X 向捲軸。
  - 在 Tag 可橫向捲動情境下，確認左右箭頭於切換尺寸後仍正確顯示。
  - 檢視左右箭頭按鈕外觀，確認非半透明且 hover 狀態正常。

- traceability:
  - Related logs: user-added/log/2026-04-22/1846-chat-chart-sizing-balance.md
  - Related logs: user-added/log/2026-04-22/1835-chat-chart-data-hydration-fix.md

- next-actions:
  - 若仍有極窄視窗邊界案例，可再補 ResizeObserver 監看 tags 容器本身尺寸變化。