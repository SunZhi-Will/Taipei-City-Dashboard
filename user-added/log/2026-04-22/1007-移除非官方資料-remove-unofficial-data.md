# 移除非官方資料顯示與推薦 / Remove Unofficial Data from Display and Recommendations

## 2026-04-22 10:07

- objective:
  - 將前端流程中的非官方（黑客松新增）組件資料從顯示與推薦管道中移除，避免出現在儀表板、地圖圖層、組件管理頁與聊天推薦中。

- files:
  - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/store/contentStore.js
  - Taipei-City-Dashboard-FE/src/store/chatStore.js

- summary:
  - 新增統一的非官方索引清單與官方判斷函式，避免在多處重複硬編碼。
  - 在內容載入流程加入官方過濾，包含 dashboard 組件、map layers 與 component 列表。
  - 在聊天向量推薦流程加入官方過濾，避免推薦非官方組件。
  - 移除儀表板卡片上的黑客松 New 標記邏輯，避免遺留非官方識別分支。

- change-type:
  - Fixed

- technical-details:
  - 新增 NON_OFFICIAL_COMPONENT_INDEXES Set 與 isOfficialComponent(component) helper。
  - contentStore：
    - setCurrentDashboardAllContent() 對 /dashboard/{index} 回傳資料先做 isOfficialComponent 過濾。
    - setMapLayers() 對 map-layers 全城市資料先做 isOfficialComponent 過濾，再去重。
    - getAllComponents() 在權限過濾前先做 isOfficialComponent 過濾。
  - chatStore：
    - queryByVector() 對 /vector/component 回傳結果先做 isOfficialComponent 過濾。
  - DashboardComponent：
    - 移除 HACKATHON_COMPONENT_INDEXES 與 isHackathonComponent 計算邏輯。
    - 移除標題區 New badge 顯示條件。

- verification:
  - 指令：以 IDE 診斷執行 get_errors 檢查以下檔案皆無錯誤：
    - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
    - Taipei-City-Dashboard-FE/src/store/contentStore.js
    - Taipei-City-Dashboard-FE/src/store/chatStore.js
    - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - 檢查結果：No errors found。

- performance-impact:
  - 影響極小；新增的 Set membership 過濾為 O(1) 查詢，整體僅增加線性掃描成本，與既有排序/去重步驟同量級。

- impact-risk:
  - 若後端新增其他非官方索引但未加入清單，仍可能被顯示。
  - 目前以 index 白名單排除，需維護清單與後端資料定義一致。
  - 降級策略：可暫時回復到僅隱藏標記，不阻擋資料載入（本次未採用）。

- regression-test:
  - 建議驗證項目：
    - /dashboard 與 /mapview 不再出現索引：aed_map、aed_district_tpe、indigenous_district_tpe、indigenous_group_tpe、migrant_workers_tpe、long_term_care_abc_map、long_term_care_abc_district_tpe。
    - /component 列表中上述索引不存在。
    - Chat fallback 推薦（vector）中上述索引不存在。
    - 其餘官方組件顯示、圖層切換、推薦建立儀表板流程不受影響。
  - 建議環境：本機 FE 開發環境與整合環境各一輪。

- traceability:
  - N/A

- next-actions:
  - 建議後續在後端 API 加入 official_flag 欄位，前端可改為欄位判斷以降低索引清單維護成本。
