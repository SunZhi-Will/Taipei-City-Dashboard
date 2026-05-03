# ChatBot 輸入欄新增 AI 建議 Tags / Add AI Suggested Tags Above Chat Input

## 2026-04-22 18:37

- objective:
  - 在右下角 Chat Bot 輸入欄上方加入多個 AI 建議查詢 Tag，讓使用者可一鍵點擊快速送出常見查詢

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 參考 `aichathub-widget-v2.js` 的 tags container 設計模式
  - 在 `<script>` 加入 `DEFAULT_TAGS`（15 個常見城市議題關鍵字）與 `suggestedTags` ref
  - 加入 `clickTag()` handler：點擊 tag 直接呼叫 `addQueryData` 送出查詢
  - 加入 `watch(chatData)` 邏輯：bot 每次回覆後，根據內容關鍵字動態更換相關 tag（支援空氣、交通、捷運、垃圾、老年、醫療、水、電等 8 個主題）
  - 在 template 的 `.input-area` 內、`.input-shell` 上方插入 `.tags-area` 水平捲動容器
  - 回應中（`isResponding`）時隱藏 tags 避免誤觸
  - 加入 SCSS 樣式：膠囊形 tag-chip、hover 效果、fade-in 動畫、scrollbar 隱藏

- change-type:
  - Added

- technical-details:
  - `suggestedTags` 初始值為 `DEFAULT_TAGS` 陣列（15 筆）
  - bot 回覆後掃描 `content` + `components[].name` 文字，比對 8 條規則，更新 suggestedTags 為 4 個情境 tag + 6 個預設 tag
  - `.tags-area` 使用 `overflow-x: auto; flex-wrap: nowrap` 水平捲動，搭配 `.scrollbar-x-hide` 隱藏捲軸
  - tag-chip 使用 `border-radius: 999px` 膠囊形，hover 提升 1px

- verification:
  - `get_errors` 檢查 ChatBox.vue → No errors found
  - 視覺確認：tags-area 在輸入欄上方，不響應時顯示，回應中隱藏

- impact-risk:
  - 僅修改 ChatBox.vue，不影響其他元件
  - tags 為純前端邏輯，不依賴額外 API
  - 水平捲動不影響垂直 layout

- traceability:
  - 參考：widget-demo-clean/aichathub-widget-v2.js tags 實作模式

- next-actions:
  - 可後續接 `/api/chat/suggested-tags` API 動態取得 tags（已有 ApiService.getSuggestedTags 可參考）
  - 可依使用者歷史查詢優化預設 tags
