# 修正非官方儀表板索引清單 - 對應實際資料庫值 / Fix Non-Official Dashboard Index List - Match Actual DB Values

## 2026-04-22 13:09

- objective:
  - 左側導覽列仍顯示非官方儀表板項目
  - 原因：硬編碼的非官方索引清單與實際資料庫中的索引值不符
  - 需更新清單以符合真實索引

- files:
  - Taipei-City-Dashboard-FE/src/constants/nonOfficialComponentIndexes.js

- summary:
  - 發現實際資料庫中的非官方儀表板索引值：
    - `ltc_care_tpe` - 長照關懷（臺北）
    - `indigenous_social_tpe` - 原住民族人口（臺北）
    - `long_term_care_abc_tpe_dashboard` - 長照ABC據點（臺北）
    - `ltc_care_newtpe` - 長照關懷（新北）
    - `ltc_care_metrotaipei` - 長照（雙北）等變體
  - 擴展 NON_OFFICIAL_DASHBOARD_INDEXES Set，納入所有已識別的實際索引值
  - 新增索引共計 25 個，涵蓋所有已知命名變體

- change-type:
  - Fixed

- technical-details:
  - 更新前的清單：16 個索引（多為推測值）
  - 更新後的清單：25 個索引（包含已驗證的實際索引）
  - 新增項目：
    - `indigenous_social_tpe`、`indigenous_social_newtpe`（原住民）
    - `long_term_care_abc_tpe_dashboard`、`ltc_care_tpe`、`ltc_care_newtpe`、`ltc_care_metrotaipei`（長照）

- verification:
  - IDE 診斷檢查：No errors found
  - 等待用戶清除快取並重新整理確認過濾生效

- performance-impact:
  - 無影響；Set 查詢仍為 O(1)

- impact-risk:
  - 若後續仍有未列出的非官方索引，左側導覽列可能繼續顯示
  - 建議後端改進：在 dashboard API 回傳中加入 `official_flag` 或 `is_official` 欄位

- regression-test:
  - 清除瀏覽器快取並硬性重新整理（Ctrl+Shift+R）
  - 確認左側導覽列不顯示長照、原住民、移工等非官方儀表板
  - 若仍有非官方項目顯示，記下 index 值並繼續擴展清單

- traceability:
  - 相關 log：
    - user-added/log/2026-04-22/1007-移除非官方資料-remove-unofficial-data.md
    - user-added/log/2026-04-22/1016-側欄非官方主題過濾修正-sidebar-unofficial-dashboard-filter.md
    - user-added/log/2026-04-22/1021-擴大非官方儀表板過濾與強化檢查-expand-unofficial-dashboard-filter.md

- next-actions:
  - 立即通知後端在 dashboard 表新增 `official_flag` 欄位，減少前端維護負擔
  - 考慮實施自動化索引檢測機制
