# 擴大非官方儀表板過濾清單與強化檢查機制 / Expand Non-Official Dashboard Filter List and Strengthen Check Logic

## 2026-04-22 10:21

- objective:
  - 修正非官方儀表板（包括 AED、原住民、移工、長照 ABC）仍顯示在左側導覽列的問題。
  - 擴大非官方儀表板索引清單，涵蓋所有可能的命名變體。
  - 在 setCurrentDashboardAllContent() 中加入顯式檢查，立即阻擋非官方儀表板存取。

- files:
  - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
  - Taipei-City-Dashboard-FE/src/store/contentStore.js

- summary:
  - 將非官方儀表板清單從單一 "aed" 索引擴展為包含所有已知變體：
    - AED 系列：aed, aed_map, aed_tpe, aed_metrotaipei
    - 原住民系列：indigenous, indigenous_tpe, indigenous_metrotaipei
    - 移工系列：migrant_workers, migrant_workers_tpe, migrant_workers_metrotaipei
    - 長照系列：long_term_care_abc, ltc_abc, ltc_abc_tpe, long_term_care_abc_tpe 等
  - 在 setCurrentDashboardAllContent() 最開始就檢查當前儀表板是否為非官方，若是則立即重定向至第一個官方儀表板。
  - 若儀表板清單尚未載入，先異步調用 setDashboards() 再重定向。

- change-type:
  - Fixed

- technical-details:
  - constants：擴展 NON_OFFICIAL_DASHBOARD_INDEXES Set，涵蓋 14 個非官方儀表板索引變體。
  - contentStore：
    - setCurrentDashboardAllContent() 前置檢查：直接判斷 isOfficialDashboard(this.currentDashboard)。
    - 若為非官方，檢查 this.dashboards.size，若為 0 則先 await setDashboards()。
    - 然後在儀表板清單中找到第一個官方儀表板並重定向。
    - 此檢查優先於既有的 currentDashboardInfo 尋找邏輯，確保非官方儀表板被徹底阻擋。

- verification:
  - 以 IDE 診斷檢查：
    - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js
    - Taipei-City-Dashboard-FE/src/store/contentStore.js
  - 結果：No errors found。

- performance-impact:
  - 低；新增檢查在 setCurrentDashboardAllContent() 最開始，若用户直接訪問非官方儀表板 URL，會立即重定向，減少不必要的 API 呼叫。

- impact-risk:
  - 新增的非官方儀表板索引清單可能不夠完整。若有其他非官方索引未列出，仍可能被顯示。
  - 此方案基於 index 硬編碼，仍建議後端補 official_flag。

- regression-test:
  - 建議驗證：
    - 直接訪問 /mapview?index=aed 或其他非官方儀表板應自動重定向。
    - 左側導覽列不顯示任何非官方儀表板項目。
    - 官方儀表板正常加載與切換。
    - 地圖視圖與儀表板視圖皆不顯示非官方內容。

- traceability:
  - 関連 log：
    - user-added/log/2026-04-22/1007-移除非官方資料-remove-unofficial-data.md
    - user-added/log/2026-04-22/1016-側欄非官方主題過濾修正-sidebar-unofficial-dashboard-filter.md

- next-actions:
  - 建議立即向後端反映，在 dashboard API 回傳中補 official_flag 或 is_official 欄位，降低前端硬編碼維護成本。
