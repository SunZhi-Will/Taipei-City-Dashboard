# 食安圖表切換與儀表板精簡 / Food Safety Chart Toggle And Dashboard Trim

## 2026-05-03 05:21

- objective:
  - 讓食安分類組件可切換圓餅圖
  - 從 food_safety_tpe 移除新北市食品工廠清冊

- files:
  - migrations/add_food_safety_components.sql
  - migrations/food_safety_components.sql

- summary:
  - 將 `food_poisoning_cause`、`food_poisoning_food`、`food_poisoning_place` 的 chart types 擴充為 `BarChart,DonutChart`
  - 將 `food_safety_tpe` 的 components 陣列移除 `ntpc_food_factory`
  - 套用 migration 後，再重跑補完 migration，保留 `school_kitchen_imap` 與 `wholesale_pesticide_inspection` 兩個既有食安組件

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `add_food_safety_components.sql`
    - `component_charts.types`：
      - `food_poisoning_cause` → `{BarChart,DonutChart}`
      - `food_poisoning_food` → `{BarChart,DonutChart}`
      - `food_poisoning_place` → `{BarChart,DonutChart}`
    - `food_safety_tpe.components` 移除 `v_ntpc_factory_cid`
  - `food_safety_components.sql`
    - 同步將同名組件的 `types` 與 metrotaipei dashboard components 對齊
  - 現場 DB 套用順序：
    - 先重跑 `add_food_safety_components.sql`
    - 再重跑 `add_school_kitchen_wholesale_components.sql`，將 `school_kitchen_imap`、`wholesale_pesticide_inspection` 補回 dashboard

- verification:
  - DB 驗證：
    - `SELECT index, types FROM component_charts WHERE index IN ('food_poisoning_cause','food_poisoning_food','food_poisoning_place') ORDER BY index;`
    - 結果均為 `{BarChart,DonutChart}`
  - DB 驗證：
    - `SELECT index, components FROM dashboards WHERE index IN ('food_safety_tpe','food_safety_taipei') ORDER BY index;`
    - `food_safety_tpe = {45,47,48,49,50,37,52}`
    - `food_safety_taipei = {45,47,48,49,50,37,52}`
    - 兩者皆不含 `46`（`ntpc_food_factory`）
  - API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=metrotaipei' | jq '.data[] | {index: .index, chart_types: .chart_config.types}'`
    - `food_poisoning_cause`、`food_poisoning_food`、`food_poisoning_place` 均回傳 `BarChart` 與 `DonutChart`

- performance-impact:
  - 僅 metadata 調整，無額外查詢成本

- impact-risk:
  - 單獨重跑 `add_food_safety_components.sql` 會先覆寫 dashboard components；若要維持完整 7 組件，需再跑 `add_school_kitchen_wholesale_components.sql`
  - 本次未移除 `ntpc_food_factory` 的 component/map metadata，只是不再掛到 food safety dashboard

- regression-test:
  - 打開 food_safety_tpe，確認三個分類組件可在 Bar 與 Donut 間切換
  - 確認 dashboard 中不再出現「新北市食品工廠清冊」
  - 確認「臺北市學校廚房稽查」與「雙北蔬果農藥檢驗」仍存在

- traceability:
  - related log:
    - user-added/log/2026-05-03/0516-init-migration-completeness-fix.md

- next-actions:
  - 若要避免手動重跑單一 migration 時洗掉補完組件，可再把 `add_food_safety_components.sql` 改為保留既有 `school_kitchen_imap` / `wholesale_pesticide_inspection`
