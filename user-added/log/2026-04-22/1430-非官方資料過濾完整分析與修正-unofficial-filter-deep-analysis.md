# 非官方資料過濾 - 完整深度分析與修正 / Unofficial Data Filtering - Complete Deep Analysis and Fix

## 2026-04-22 14:30

- objective:
  - 徹底分析非官方資料過濾問題
  - 找出真實的官方 vs 非官方儀表板清單
  - 修正過度過濾導致官方資料也消失的問題

- files:
  - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
  - Taipei-City-Dashboard-FE/src/store/contentStore.js

- summary:

  ### 根本問題發現
  - 之前的過濾清單是基於推測，導致官方儀表板被誤殺
  - 官方資料消失，表示過濾邏輯太激進

  ### 深度分析過程
  1. 查閱 codefest-main.md：確認這是黑客松項目
  2. 查看 complete-project-analysis.md：了解官方 vs 黑客松新增主題
  3. **關鍵發現**：查詢 db-sample-data/dashboardmanager-demo.sql
     - 官方儀表板只有 5 個
  4. **終極來源**：user-added/2025-last-year/my-data/sql/03_dashboardmanager_inserts.sql
     - 黑客松明確插入的非官方儀表板只有 **4 個**

  ### 真實的儀表板清單

  **官方儀表板（應保留）**：
  - `map-layers-taipei` - 圖資資訊
  - `ltc_care_tpe` - 長照關懷（臺北）
  - `ltc_care_newtpe` - 長照關懷（新北）
  - `map-layers-metrotaipei` - 圖資資訊
  - `practical_transportation_newtpe` - 務實交通

  **非官方儀表板（黑客松 2025 年新增，應移除）**：
  - `aed_tpe` - AED 分布
  - `indigenous_social_tpe` - 原住民族人口
  - `migrant_workers_tpe` - 受聘僱移工
  - `long_term_care_abc_tpe_dashboard` - 長照ABC據點

  ### 修正內容
  1. NON_OFFICIAL_DASHBOARD_INDEXES：從 25 個推測索引縮小到 **4 個真實索引**
  2. 恢復 isOfficialDashboard 過濾邏輯在 setDashboards()
  3. setCurrentDashboardAllContent() 自動處理重定向（已原有邏輯支持）
  4. 添加數據來源註釋指向 SQL 文件

- change-type:
  - Fixed

- technical-details:
  - 過濾邏輯修正：
    ```javascript
    export const NON_OFFICIAL_DASHBOARD_INDEXES = new Set([
        "aed_tpe",
        "indigenous_social_tpe",
        "migrant_workers_tpe",
        "long_term_care_abc_tpe_dashboard",
    ]);
    ```
  - 過濾被應用在 setDashboards() 的 filter(isOfficialDashboard)
  - setCurrentDashboardAllContent() 的 currentDashboardInfo 檢查會自動捕捉非官方儀表板
  - 非官方儀表板若被直接訪問，會被重定向到第一個官方儀表板

- verification:
  - IDE 診斷檢查：No errors found
  - 等待用戶清除快取（Ctrl+Shift+R）後驗證

- performance-impact:
  - 無；Set 查詢仍為 O(1)

- impact-risk:
  - 低；清單來自官方黑客松 SQL 初始化腳本，可信度高

- regression-test:
  - 清除瀏覽器快取並硬性重新整理
  - 確認左側導覽列只顯示官方儀表板：
    - ✅ 圖資資訊
    - ✅ 長照關懷
    - ✅ 務實交通
  - 確認不顯示非官方儀表板：
    - ❌ AED 分布
    - ❌ 原住民族人口
    - ❌ 受聘僱移工
    - ❌ 長照ABC據點
  - 若直接訪問非官方儀表板 URL，應自動重定向

- traceability:
  - **官方數據來源**：
    - db-sample-data/dashboardmanager-demo.sql（官方儀表板）
    - user-added/2025-last-year/my-data/sql/03_dashboardmanager_inserts.sql（黑客松儀表板定義）
  - 相關 commit/log：
    - codefest-main.md（活動說明）
    - user-added/2026-this-year/docs/02-project-analysis/complete-project-analysis.md

- next-actions:
  - 用戶驗證修正是否生效
  - 如有新的非官方索引變種，更新 NON_OFFICIAL_DASHBOARD_INDEXES
  - 建議後端在 dashboard 表添加 `official_flag` 欄位以完全消除前端硬編碼

- lessons-learned:
  - **深度分析的重要性**：在沒有真實數據來源的情況下進行過濾會導致誤殺
  - **追溯數據源**：SQL 初始化腳本是真相之源
  - **宣傳透明**：在代碼中明確標註數據來源和版本
