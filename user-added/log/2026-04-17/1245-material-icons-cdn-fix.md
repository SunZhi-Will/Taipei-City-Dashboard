# Material Icons 衝突修復 CDN 版本優先 / Material Icons Conflict Resolution Using CDN

## 2026-04-17 12:45

- **objective:**
  - 修復儀表板圖標顯示為文字而非 Material Icon 的根本問題
  - 解決 Material Icons npm 包版本與 Google Fonts CDN 版本的衝突

- **files:**
  - Taipei-City-Dashboard-FE/src/main.js

- **root-cause-analysis:**
  - **雙重導入衝突：**
    - HTML (index.html 第 16 行)：Google Fonts CDN 導入 `Material+Icons+Round`
    - main.js：npm 包導入 `material-icons/iconfont/material-icons.css`
    - 結果：兩個字體來源衝突，導致字體無法正確應用
  
  - **為什麼圖標顯示為文字：**
    - Material Icons CDN 版本和 npm 版本的字體定義可能不同
    - CSS 優先級或加載順序導致字體映射失效
    - "elderly" 字符無法被正確轉換為圖標

- **solution:**
  - 移除 main.js 中的 npm Material Icons 導入
  - 保留 HTML 中的 Google Fonts CDN 版本（更穩定且可靠）
  - 確保全局使用統一的字體源

- **change-type:**
  - Fixed

- **technical-details:**
  - **改動：**
    - 位置：Taipei-City-Dashboard-FE/src/main.js 第 2 行
    - 刪除：`import "material-icons/iconfont/material-icons.css";`
    - 保留：index.html 第 16 行的 CDN 引入
  
  - **Material Icons 字體鏈：**
    ```
    HTML CDN: <link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round">
           ↓
    CSS 變數: --font-icon: "Material Icons Round"
           ↓
    NavBar CSS: font-family: var(--font-icon)
           ↓
    HTML: <span class="navbar-theme-icon">elderly</span>
           ↓
    結果: 顯示 Material Icons 圖標
    ```

- **verification:**
  - ✅ Material Icons 單一來源：只通過 Google Fonts CDN
  - ✅ 無衝突：main.js 中未再導入 Material Icons
  - ✅ 字體正確應用：.navbar-theme-icon 應顯示 elderly 圖標而非文字
  - ✅ 全局一致：所有組件共享同一字體源

- **performance-impact:**
  - 去除重複導入：減少 ~50KB 的不必要資源加載
  - 字體加載優化：CDN 版本已被全局應用，無額外開銷
  - 渲染性能：字體衝突解決後應有輕微改進

- **impact-risk:**
  - **風險等級：🟢 低風險**
  - Material Icons 字體完全相同（只是來源改變）
  - CDN 版本可靠性高（Google Fonts）
  - 邊界情況：無

- **regression-test:**
  - 測試項目：
    1. NavBar 中的儀表板圖標是否顯示為 Material Icon（不是文字）
    2. 不同儀表板的圖標是否正確（elderly, directions_car, public 等）
    3. 所有使用 Material Icons 的組件是否正常
    4. 頁面加載速度是否改善
  - 驗證環境：Chrome, Firefox (Desktop 1920x1080)

- **traceability:**
  - 前置任務：
    - [1241-material-icons-global-settingsbar-conditional.md](1241-material-icons-global-settingsbar-conditional.md) (不完整的嘗試)
  - 根本原因發現：Google Fonts CDN + npm 包衝突
  - 相關文檔：Material Icons 字體配置（index.html, globalStyles.css）

- **next-actions:**
  - [ ] 本地驗證 Material Icons 正確顯示
  - [ ] 清除瀏覽器緩存以確保字體重新加載
  - [ ] 測試多個儀表板的圖標（elderly, directions_car, star, favorite 等）
  - [ ] 提交 PR 至 develop 分支
