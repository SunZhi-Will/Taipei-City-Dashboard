# AI Studio Header 與收合體驗修正 / AI Studio Header and Collapse UX Fix

## 2026-04-23 17:14

- objective:
  - 將垃圾桶按鈕位置調整為靠近右側收合按鈕
  - 修正左面板收合時內容被擠壓、文字瞬間換行過多的視覺問題

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 調整左面板 header 結構，將「清除聊天」與「收合/展開」放在同一個右側 actions 區。
  - 取消左面板寬度動畫（width/min-width transition），改為即時切換寬度，避免收合過程造成右側內容逐步壓縮與重排。

- change-type:
  - Fixed

- technical-details:
  - template：
  - 新增 `.aistudio-left-actions` 容器
  - 垃圾桶按鈕移入 `.aistudio-left-actions`
  - 收合按鈕與垃圾桶按鈕並列於右側
  - style：
  - `.aistudio-left` 的 transition 由 `width/min-width` 改為 `border-color`，不再對寬度做動畫
  - 新增 `.aistudio-left-actions` 樣式：`inline-flex + gap + margin-left: auto`

- verification:
  - 檢查方式：編輯器 Problems 診斷
  - 結果：`AIStudioView.vue` 無錯誤（No errors found）
  - 檢查方式：模板內容確認
  - 結果：垃圾桶與收合按鈕同區塊，位置可控且靠右

- performance-impact:
  - 輕微正向
  - 移除寬度動畫可降低收合過程中的 reflow/repaint 次數

- impact-risk:
  - 低風險
  - 僅調整 AI Studio View 的版面與動畫，不改聊天資料邏輯

- regression-test:
  - 開啟 `/ai-studio`，確認垃圾桶按鈕緊鄰收合按鈕
  - 收合左面板時，右側內容不再有明顯擠壓換行過程
  - 展開/收合反覆測試 5 次，確認按鈕位置與行為穩定

- traceability:
  - user request: 「上方垃圾桶位置太奇怪了 他應該靠近右邊的收起按鈕；另外收起時內容不要感覺被壓縮」

- next-actions:
  - N/A
