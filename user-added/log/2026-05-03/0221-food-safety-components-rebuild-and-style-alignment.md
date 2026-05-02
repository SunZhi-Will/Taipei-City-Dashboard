# 食安組件重建與樣式對齊 / Food Safety Components Rebuild and Style Alignment

## 2026-05-03 02:21

- objective:
  - 依照參考畫面重建食安組件與 dashboard
  - 讓圖表預設型別、顏色與顯示順序更接近參考樣式
  - 確保組件資料直接讀取 dashboard DB，而非使用硬編碼常數

- files:
  - migrations/food_safety_components.sql

- summary:
  - 重新設計 food_safety_components.sql，改為可重複執行的完整 migration，重建 components、component_charts、component_maps、query_charts、dashboards、dashboard_groups
  - 套用後建立 7 個食安組件與 food_safety_tpe dashboard
  - 將食安組件名稱改為更貼近參考畫面的標題，如「食品業者衛生稽查地圖」、「可能中毒食品分布」、「致病原因分布」、「雙北蔬果農藥檢驗」
  - 調整 chart types 與順序：food_poisoning_food / food_poisoning_cause 預設改為 DonutChart，保留 BarChart 切換；dashboard 排序改為稽查 donut → 食品 donut → 原因 donut → 月度統計
  - 將 query_charts 改為直接查詢 dashboard DB 內 7 張食安資料表，移除舊的硬編碼數字依賴

- change-type:
  - Fixed
  - Changed

- technical-details:
  - components 重建為：taipei_imap_food、ntpc_food_factory、food_poisoning_trend、food_poisoning_cause、food_poisoning_food、food_poisoning_place、wholesale_pesticide_inspection
  - component_charts 調整：
    - taipei_imap_food：綠/黃/紅 donut
    - food_poisoning_food：藍色系為主，types = {DonutChart, BarChart}
    - food_poisoning_cause：紅色系為主，types = {DonutChart, BarChart}
    - food_poisoning_trend：types = {AnimatedColumnChart, TimelineSeparateChart}
  - dashboard 組件順序調整為 {1,5,4,3,6,7,2}
  - query_charts 改為動態 SQL：
    - taipei_imap_food：A1/A2→合格、A3→正在複查、其他→不合格
    - ntpc_food_factory：COUNT(*)
    - wholesale_pesticide_inspection：result='合格' 與其他結果二分統計

- verification:
  - `cat migrations/food_safety_components.sql | docker exec -i postgres-manager psql -U postgres -d dashboardmanager` → `BEGIN / DO / COMMIT`
  - `curl http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=taipei` → 回傳 7 個食安組件，名稱、types、color 已更新
  - `curl http://localhost:8088/api/v1/component/1/chart?city=taipei` → 合格 12774 / 正在複查 689 / 不合格 232
  - `curl http://localhost:8088/api/v1/component/2/chart?city=taipei` → 工廠總數 1230
  - `curl http://localhost:8088/api/v1/component/7/chart?city=taipei` → 合格 37697 / 不合格 1557

- performance-impact:
  - 組件圖表由靜態常數改為動態 SQL 統計，查詢成本較過去略高
  - 目前資料量仍在可接受範圍（單表 4 萬筆等級），未觀察到 API 失敗或超時

- impact-risk:
  - 本次僅重建 food_safety_tpe 與 7 個食安組件，不會恢復其他已清空 dashboard
  - wholesale_pesticide_inspection 改為全量統計後，數值與先前靜態展示差異大，屬預期行為
  - 若前端需要完全複刻參考畫面，仍需補建 school_kitchen_imap 與額外月趨勢組件

- regression-test:
  - 打開 food_safety_tpe，確認第一排預設為綠色稽查 donut、藍色食品 donut、紅色原因 donut
  - 切換 food_poisoning_food / food_poisoning_cause 的 chart type，確認 DonutChart 與 BarChart 都可正常顯示
  - 驗證 taipei 與 metrotaipei city 參數都可回傳相同食安組件設定

- traceability:
  - 備份檔：/tmp/dashboardmanager_components_backup_20260503_021011.sql
  - 相關資料檔：migrations/food_safety_data.sql

- next-actions:
  - 可補建 school_kitchen_imap 與雙北蔬果不合格月趨勢，讓 dashboard 更貼近參考畫面
  - 若要完全統一雙北語意，可把 food_safety_tpe 名稱與 city 策略進一步收斂為 metrotaipei-only