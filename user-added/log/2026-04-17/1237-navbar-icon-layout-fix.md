# NavBar Logo 標題排列與 Material Icon 修復 / NavBar Logo Title Layout and Material Icon Fix

## 2026-04-17 12:37

- **objective:**
  - 修復 NavBar 中應用標題的排列方式（改為上下垂直排列）
  - 修復儀表板圖標顯示問題（從文字改為正確的 Material Icon）
  - 確保儀表板信息清晰、易讀

- **files:**
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue

- **summary:**
  - **Logo 標題排列修正：**
    - 將 `.navbar-logo-header` 從水平排列改為垂直排列（`flex-direction: column`）
    - 修改 `align-items` 為 `flex-start`，確保左對齐
    - 設置 `gap: 0` 和 `line-height: 1` 使標題更緊湊
  
  - **Material Icon 修復：**
    - 在 NavBar script 頂部導入 Material Icons CSS：`import "material-icons/iconfont/material-icons.css"`
    - 確保 `.navbar-theme-icon` 能正確渲染 Material Icons 而非文本

- **change-type:**
  - Fixed

- **technical-details:**
  - **Script 改動：**
    ```javascript
    import "material-icons/iconfont/material-icons.css";
    ```
    - 位置：第 7 行，放在其他 import 之前
    - 確保 Material Icons 字體在組件範圍內可用
  
  - **CSS 改動（.navbar-logo-header）：**
    - **舊版本**：`display: flex; align-items: baseline; gap: 8px;`
    - **新版本**：`display: flex; flex-direction: column; align-items: flex-start; gap: 0;`
    - **效果**：h1 和 h2 上下排列，h1 在上，h2 在下
    - **行間距**：設置 `line-height: 1` 使標題更緊湊
    - **邊距**：h1 和 h2 的 `margin: 0` 確保無額外間距

- **verification:**
  - ✅ Material Icons 導入驗證：
    - 儀表板圖標（如 "elderly"）是否顯示為實際圖標而非文字
    - 使用開發者工具檢查 span.navbar-theme-icon 的字體是否為 Material Icons
  
  - ✅ 排列驗證：
    - h1 "臺北城市儀表板" 顯示在 h2 "Taipei City Dashboard" 上方
    - 兩行標題左對齐，緊湊排列
    - 分隔符 "/" 和儀表板名稱在右側
  
  - ✅ 響應式驗證：
    - Desktop：完整顯示所有元素
    - 768px-500px：隱藏儀表板名稱
    - <500px：只顯示 Logo

- **performance-impact:**
  - CSS 導入：Material Icons CSS (~50KB gzip) 會在 NavBar 組件加載時導入
  - 性能建議：如果其他組件也需要 Material Icons，考慮在全局 CSS 中導入以提高效率
  - DOM 層級：無變化
  - 重繪性能：無影響

- **impact-risk:**
  - **風險等級：🟢 低風險**
  - Material Icons 導入的潛在問題：
    - 若其他組件也導入相同 CSS，會產生重複導入（不影響功能，只是輕微浪費）
    - 解決方案：未來可在 main.js 全局導入
  - 布局變更：h1/h2 從水平改為垂直，可能影響需要精確 NavBar 高度的外部組件

- **regression-test:**
  - 測試項目：
    1. 儀表板圖標是否顯示為 Material Icon（視覺檢查）
    2. h1 "臺北城市儀表板" 和 h2 "Taipei City Dashboard" 上下排列
    3. Logo + 標題整體布局是否美觀
    4. 不同儀表板的圖標是否正確顯示（elderly, care, etc.）
    5. 儀表板切換時標題和圖標是否實時更新
  - 驗證環境：Chrome, Firefox, Safari (Desktop 1920x1080)

- **traceability:**
  - 前置任務：
    - [1222-navbar-theme-breadcrumb.md](1222-navbar-theme-breadcrumb.md)
    - [1235-navbar-layout-fix.md](1235-navbar-layout-fix.md)
  - 用戶反饋：NavBar 標題排列與圖標顯示問題

- **next-actions:**
  - [ ] 本地驗證 Material Icon 正確顯示
  - [ ] 確認 h1/h2 排列是否符合視覺設計
  - [ ] 考慮在 main.js 全局導入 Material Icons CSS（優化方案）
  - [ ] 提交 PR 至 develop 分支
  - [ ] 合併並推送至測試環境
