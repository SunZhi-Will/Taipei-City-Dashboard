# ChatBox 深色系主題應用 / Dark Mode Theme Applied to ChatBox

## 2026-04-22 13:19

- objective:
  - 將 ChatBox 組件改為深色系主題，背景變成灰色，文字改為白色，提升夜間使用體驗

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 修改 SCSS 變數：主背景色 `#f8fafc` → `#1e1e2e`（深灰色）
  - 修改面板背景：`#18181b` → `#0f0f17`（更深的背景）
  - 修改卡片背景：`#ffffff` → `#2a2a38`（灰色卡片）
  - 修改邊框色：`#e4e4e7` → `#3a3a48`（深色邊框）
  - 修改輸入框背景：`#ffffff` → `#2a2a38`（深灰色輸入框）
  - 調整所有文字顏色為白色 `#ffffff` 或淺灰色 `#e0e0e8`
  - 更新表格顏色方案、按鈕樣式、置頂公告、訊息氣泡等所有 UI 元素
  - 優化陰影和懸停效果以適應深色主題

- change-type:
  - Changed

- technical-details:
  - 變數層級修改：確保整個組件主題統一
  - 文字對比度：白色文字 (#ffffff) 在深灰色背景上確保可讀性
  - 按鈕狀態：懸停時使用 brightness(1.3) 而非 brightness(0.92)
  - 表格表頭：背景色改為 #24242e，文字為白色
  - 訊息氣泡：用戶訊息氣泡改為深藍色 #3a5f7a，保持對比
  - 關聯表格：背景 #2a2a38，邊框 #3a3a48
  - 陰影層級：增加陰影深度以適應深色背景
  - Scrollbar：捲軸顏色調整為 #606070

- verification:
  - 執行 `get_errors` 檢查：ChatBox.vue 無編譯錯誤
  - SCSS 變數完整應用至所有相關 class
  - 所有顏色值已完成替換，主題統一

- performance-impact:
  - 無效能影響，純 CSS 主題切換

- impact-risk:
  - 涉及範圍：整個 ChatBox 視覺呈現
  - 已知風險：無
  - 相容性：所有現代瀏覽器支援

- regression-test:
  - [ ] 在不同螢幕亮度下驗證文字可讀性
  - [ ] 檢查所有訊息類型顯示效果（機器人、使用者、置頂公告）
  - [ ] 驗證表格和按鈕懸停效果
  - [ ] 測試輸入框焦點狀態
  - [ ] 移動設備上的深色主題表現

- traceability:
  - 相關修改：2026-04-22 1052-chat-sticky-no-side-gap.md （前次調整）
  - User request: 「裡面也使用深色系 變成灰色背景白色字」

- next-actions:
  - 根據使用者反饋進行微調（如有需要）
  - 考慮加入淺色/深色模式切換功能
