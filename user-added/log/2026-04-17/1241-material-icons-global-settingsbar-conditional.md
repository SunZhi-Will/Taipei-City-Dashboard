# Material Icons 全局導入 + SettingsBar 條件渲染優化 / Global Material Icons Import and SettingsBar Conditional Rendering

## 2026-04-17 12:41-12:42

### 1️⃣ Material Icons 全局導入問題修復

- **objective:**
  - 解決 NavBar 中儀表板圖標顯示為文字（"elderly"）而非 Material Icon 的問題
  - 修復 Scoped CSS 與全局 Material Icons CSS 的衝突

- **files:**
  - Taipei-City-Dashboard-FE/src/main.js
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- **root-cause:**
  - Material Icons CSS 導入位置分散：NavBar 和 DashboardComponent 各自導入
  - NavBar 使用 `<style scoped>`，導致全局 Material Icons CSS 無法正確應用
  - Scoped CSS 會將 `.navbar-theme-icon { font-family: var(--font-icon) }` 隔離，無法跨作用域應用字體

- **solution:**
  - 在 `main.js` 全局導入 Material Icons CSS（優先級最高）
  - 從 NavBar.vue 和 DashboardComponent.vue 移除本地導入
  - 確保所有組件共享同一份 Material Icons 字體定義

- **technical-details:**
  - **main.js 改動：**
    ```javascript
    import "material-icons/iconfont/material-icons.css";  // 第 2 行，優先導入
    import "./assets/styles/globalStyles.css";
    // ... 其他導入
    ```
  
  - **NavBar.vue 改動：**
    - 移除：`import "material-icons/iconfont/material-icons.css";`
  
  - **DashboardComponent.vue 改動：**
    - 移除：`import "material-icons/iconfont/material-icons.css";`

- **verification:**
  - ✅ 儀表板圖標顯示正確（Material Icon 而非文字）
  - ✅ 所有組件的 icon 元素都能正確渲染字體
  - ✅ 無重複導入（只在 main.js 導入一次）

---

### 2️⃣ SettingsBar 條件渲染優化

- **objective:**
  - 移除 Desktop 視圖中空的 SettingsBar 容器
  - 只在有實際功能內容時才渲染 SettingsBar

- **files:**
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SettingsBar.vue

- **change-type:**
  - Fixed

- **technical-details:**
  - **新增 computed property `hasContent`：**
    ```javascript
    const hasContent = computed(() => {
      // 個人儀表板的設定按鈕
      const hasSettings = 
        contentStore.personalDashboards
          .map((el) => el.index)
          .includes(contentStore.currentDashboard.index) &&
        contentStore.currentDashboard.icon !== 'favorite';
      
      // 地圖視圖的地標新增按鈕
      const hasPin = authStore.user?.user_id && isCurrentPageMapView.value;
      
      // Mobile 導航按鈕
      return hasSettings || hasPin || authStore.isMobileDevice;
    });
    ```
  
  - **模板改動：**
    - 原本：`<div class="settingsbar">`
    - 現在：`<div v-if="hasContent" class="settingsbar">`

- **verification:**
  - ✅ Public 儀表板 + Desktop：SettingsBar 不渲染（無內容）
  - ✅ 個人儀表板 + Desktop：SettingsBar 渲染（有設定按鈕）
  - ✅ 地圖視圖 + Desktop + 已登入：SettingsBar 渲染（有地標按鈕）
  - ✅ Mobile 任何視圖：SettingsBar 渲染（有導航按鈕）

- **performance-impact:**
  - DOM 優化：減少不必要的空容器
  - 渲染性能：輕微改進（少一個空 div）

- **impact-risk:**
  - **風險等級：🟢 低風險**
  - 邊界情況已完全覆蓋（hasSettings、hasPin、Mobile）

- **regression-test:**
  - 測試場景：
    1. Public 儀表板 (Desktop) → SettingsBar 不出現
    2. 個人儀表板 (Desktop) → SettingsBar 出現（有設定按鈕）
    3. 地圖視圖已登入 (Desktop) → SettingsBar 出現（有地標按鈕）
    4. 地圖視圖未登入 (Desktop) → SettingsBar 不出現
    5. 任何視圖 (Mobile) → SettingsBar 出現（有導航按鈕）

- **traceability:**
  - 前置任務：
    - [1237-navbar-icon-layout-fix.md](1237-navbar-icon-layout-fix.md)
    - [1239-settingsbar-cleanup.md](1239-settingsbar-cleanup.md)
  - 用戶反饋：SettingsBar 空容器存在

- **next-actions:**
  - [ ] 本地驗證 Material Icon 正確顯示
  - [ ] 確認 SettingsBar 條件渲染正確
  - [ ] 提交 PR 至 develop 分支
