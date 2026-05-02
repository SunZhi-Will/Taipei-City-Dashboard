# 食安混合預設圖型與折線配色修正 / Food Safety Mixed Default Charts And Line Colors

## 2026-05-03 05:46

- objective:
  - 修正 food safety dashboard 幾乎全部元件預設為圓餅圖的問題
  - 修正折線圖顏色過度集中為紅色的問題

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue
  - migrations/add_food_safety_components.sql
  - migrations/food_safety_components.sql

- summary:
  - 在前端 `DashboardView` 新增 food safety 專屬預設圖型分配策略，讓不同元件進頁時直接呈現不同圖型，不再幾乎全是 Donut
  - 為 `food_poisoning_trend` 改用 12 色調色盤，讓 `TimelineSeparateChart` 顯示多條線時不再全部紅線
  - 套用 migration 更新現場 metadata，使 API 回傳的 trend colors 與前端呈現一致

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `DashboardView.vue`
    - 新增 `DASHBOARD_DEFAULT_CHART_TYPES`（`food_safety_tpe` / `food_safety_taipei`）
    - 新增 `getPreferredInitialChartType(component)`：依 dashboard + component index 指定預設圖型；若不存在則回退 `types[0]`
    - 將 `componentActiveCharts` 初始化由「全部取 `types[0]`」改為「取 `getPreferredInitialChartType`」
    - 三個 `DashboardComponent` 呼叫點（focus/half/default）之 `initial-chart-type` 改為優先使用 `getPreferredInitialChartType`
  - food safety 預設分配（避免全 Donut）：
    - `taipei_imap_food` -> `AnimatedColumnChart`
    - `food_poisoning_cause` -> `BarChart`
    - `food_poisoning_food` -> `DonutChart`
    - `food_poisoning_place` -> `BarChart`
    - `food_poisoning_trend` -> `TimelineSeparateChart`
    - `wholesale_pesticide_inspection` -> `BarChart`
  - migration 配色修正：
    - `add_food_safety_components.sql` 與 `food_safety_components.sql` 的 `food_poisoning_trend` color 改為 12 色：
      - `#EF5350,#42A5F5,#66BB6A,#FFA726,#AB47BC,#26C6DA,#8D6E63,#EC407A,#7E57C2,#29B6F6,#9CCC65,#FF7043`

- verification:
  - VS Code diagnostics：
    - `Taipei-City-Dashboard-FE/src/views/DashboardView.vue` -> No errors found
    - `migrations/add_food_safety_components.sql` -> No errors found
    - `migrations/food_safety_components.sql` -> No errors found
  - metadata 套用：
    - `docker exec -i postgres-manager psql -U postgres -d dashboardmanager < migrations/add_food_safety_components.sql`
    - `docker exec -i postgres-manager psql -U postgres -d dashboardmanager < migrations/add_school_kitchen_wholesale_components.sql`
    - 結果：兩支 migration 均 `COMMIT`
  - API 驗證：
    - `curl -s 'http://localhost:8088/api/v1/dashboard/food_safety_tpe?city=metrotaipei' | jq '.data[] | {index:.index, chart_types:.chart_config.types, colors:.chart_config.color}'`
    - 結果：
      - `food_poisoning_trend.colors` 已回 12 色調色盤
      - food safety 各組件 `chart_types` 保持可切換（如 `DonutChart/BarChart`、`AnimatedColumnChart/TimelineSeparateChart`）

- performance-impact:
  - 新增的前端預設圖型判斷僅在 dashboard components 更新時執行，成本極低
  - trend 多色配色僅影響渲染顏色，不增加資料查詢成本

- impact-risk:
  - 這次是「food safety dashboard 特例預設」，其他 dashboard 仍維持既有行為
  - 若未來調整 `chart_types` 並移除指定預設圖型，邏輯會自動回退到 `types[0]`

- regression-test:
  - 重新整理 `food_safety_tpe` / `food_safety_taipei`，確認首屏不再幾乎全是 Donut
  - 將 `food_poisoning_trend` 切至折線圖，確認多條線呈現多色
  - 驗證切換圖型後尺寸邏輯仍正常（特別是 `BarChart` 與 `TimelineSeparateChart`）

- traceability:
  - related logs:
    - user-added/log/2026-05-03/0541-food-safety-trend-line-and-map-time-animation.md
    - user-added/log/2026-05-03/0524-food-safety-donut-default-and-tile-sizing.md

- next-actions:
  - 若要更細緻控制每個 dashboard 的「預設圖型」，可將這份映射搬到後端 metadata，改由 API 下發而非前端硬編碼
