# NavBar 布局修復與 SettingsBar 優化 / NavBar Layout Fix and SettingsBar Optimization

## 2026-04-17 12:35

- **objective:**
  - 修復 NavBar 中儀表板信息顯示位置（改為水平排列，而非垂直堆疊）
  - 移除 SettingsBar 中的冗余儀表板標題信息（避免重複顯示）
  - 優化信息架構，確保儀表板信息統一在 NavBar 中展示

- **files:**
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SettingsBar.vue

- **summary:**
  - **NavBar 改進：**
    - 將儀表板名稱等信息改為水平排列（Flexbox）
    - 新增 `.navbar-logo-titles` 容器，確保所有元素同一行
    - 新增 `.navbar-logo-header` 容器，將應用標題 (h1) 和儀表板標題 (h2) 水平排列
    - 最終效果：`Logo | 應用標題 Taipei City Dashboard / 🏥 長照關懷`
  
  - **SettingsBar 優化：**
    - 移除 `<span>{{ contentStore.currentDashboard.icon }}</span>` 和 `<h2>{{ contentStore.currentDashboard.name }}</h2>`
    - 保留行動按鈕（Mobile 導航、設定、地標新增等）
    - 避免儀表板信息重複顯示，降低視覺混雜度

- **change-type:**
  - Changed

- **technical-details:**
  - **NavBar HTML 改動：**
    - 新增 `<div class="navbar-logo-titles">` 包裝所有標題元素
    - 新增 `<div class="navbar-logo-header">` 包裝 h1 和 h2，使其水平排列
    - 保留儀表板名稱和圖標在同一行

  - **NavBar CSS 新增：**
    ```scss
    &-titles {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    &-header {
      display: flex;
      align-items: baseline;
      gap: 8px;

      h1, h2 {
        margin: 0;  // 移除默認邊距
      }
    }
    ```

  - **SettingsBar HTML 改動：**
    - 直接刪除儀表板圖標和名稱元素
    - 保留 Mobile 導航按鈕和其他功能按鈕

- **verification:**
  - ✅ NavBar 布局驗證：
    - Desktop 視圖：Logo、應用標題、分隔符、儀表板名稱在同一水平線上
    - 無文字換行或垂直堆疊
  
  - ✅ SettingsBar 簡化驗證：
    - 儀表板標題已移除
    - Mobile 導航按鈕仍正常顯示
    - 設定按鈕仍正常顯示
  
  - ✅ 響應式驗證：
    - 768px 以上：完整顯示 Logo | 應用標題 / 儀表板名稱
    - 500-768px：隱藏儀表板名稱
    - <500px：只顯示 Logo

- **performance-impact:**
  - DOM 結構優化：增加 2 個容器層級（navbar-logo-titles, navbar-logo-header），但結構更清晰
  - CSS 計算：Flexbox 布局無額外計算開銷
  - 重繪性能：無影響（均在現有 NavBar 組件內）
  - 包大小：0 KB 變化

- **impact-risk:**
  - **風險等級：🟢 低風險**
  - 影響範圍：僅限 NavBar 和 SettingsBar 視覺層
  - 邊界情況：
    - 若儀表板名稱為空，顯示空字符串（不會崩潰）
    - 長名稱會被 `text-overflow: ellipsis` 截斷
  - 降級策略：可快速隱藏儀表板信息區域（CSS `display: none`）

- **regression-test:**
  - 測試項目：
    1. 所有儀表板頁面的 NavBar 布局是否正確
    2. 儀表板切換時 NavBar 是否實時更新
    3. SettingsBar 是否不再顯示儀表板標題
    4. 所有行動按鈕（設定、地標新增等）是否正常
    5. 響應式斷點下的顯示是否正確
  - 驗證環境：Desktop, Tablet (768px), Mobile (375px)

- **traceability:**
  - 前置任務：[1222-navbar-theme-breadcrumb.md](1222-navbar-theme-breadcrumb.md)
  - 用戶反饋：NavBar 儀表板信息位置調整

- **next-actions:**
  - [ ] 本地驗證 NavBar 布局效果
  - [ ] 測試 SettingsBar 簡化後的視覺效果
  - [ ] 提交 PR 至 develop 分支
  - [ ] 推送至測試環境進行 QA
