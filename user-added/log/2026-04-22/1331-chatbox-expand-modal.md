# ChatBox 全屏展開功能 / ChatBox Expand to Fullscreen Modal

## 2026-04-22 13:31

- objective:
  - 參考 widget demo 的放大功能，為 ChatBox 新增全屏展開 Modal
  - 在 header 加入展開按鈕，提供更大的聊天空間

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 新增 `isExpanded` 狀態變數追蹤全屏展開状態
  - 新增 `toggleExpand()` 方法處理展開/收起邏輯
  - 在 header-actions 中添加展開按鈕（使用上下箭頭 icon）
  - 創建全屏 modal overlay，z-index: 2147483647
  - Modal 內複製整個 ChatBox 結構（header、chat-area、input-area）
  - Modal 頂部右角添加關閉按鈕
  - Modal 點擊背景可關閉
  - 添加相應的 CSS 樣式支持 modal 佈局
  - 響應式設計：桌面版最大 1000px 寬度，90vh 高度；移動版全屏

- change-type:
  - Added

- technical-details:
  - 使用 Vue 3 ref 管理展開狀態
  - Modal 背景使用 `rgba(0, 0, 0, 0.95)` 半透明黑色
  - Modal content 使用 flexbox 列佈局，確保 header、chat-area、input-area 正確分佈
  - z-index 層級：Modal 背景 2147483647，Close button 1001
  - 採用深色系主題色彩保持一致性
  - Modal 內部複製了完整的 ChatBox 功能（聊天、輸入、清除）

- verification:
  - 執行 `get_errors` 檢查：ChatBox.vue 無編譯錯誤
  - Modal template 結構完整，所有事件綁定正確
  - 響應式 CSS 規則已添加

- performance-impact:
  - Modal 使用 v-if 懶加載，不展開時不佔用 DOM
  - 無動畫效能損耗（純 CSS fixed positioning）

- impact-risk:
  - 涉及範圍：ChatBox 全屏展開體驗
  - 已知風險：無
  - 邊界情況：超小螢幕（<300px）下 Close button 可能被擠壓

- regression-test:
  - [ ] 點擊展開按鈕驗證 modal 出現
  - [ ] 驗證 modal 內聊天功能正常（發送、清除等）
  - [ ] 測試關閉按鈕和背景點擊都能關閉 modal
  - [ ] 桌面 / 平板 / 移動設備上的全屏表現
  - [ ] 深色主題顏色一致性確認

- traceability:
  - 相關修改：2026-04-22 1319-dark-mode-chatbox.md（深色系主題）
  - 相關修改：2026-04-22 1327-white-send-button.md（白色發送按鈕）
  - User request: 「參考widget demo chat的放大功能呢」

- next-actions:
  - 考慮添加鍵盤快捷鍵（例如 Esc 關閉 modal）
  - 可優化 modal 動畫過渡效果（如淡入淡出）
  - 根據使用者反饋進行微調
