# DistrictChart 行政區圖在 ChatBot 顯示空白修正 / DistrictChart Not Rendering in ChatBot Fix

## 2026-05-02 13:53

- objective:
  - AI Chat 機器人顯示「全市年齡分區」等含 DistrictChart 組件時，行政區地圖完全不顯示（空白）

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DistrictChart.vue
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatResultComponents.vue

- summary:
  - **根本原因**：`DistrictChart.vue` 的 `cityName` computed 在 `props.activeCity` 為空或未傳入時，錯誤回傳代碼字串 `"metrotaipei"`（城市代碼），而 SVG 模板的 `v-if` 條件判斷使用中文顯示名（`"新北市"`、`"雙北市"`、`"臺北市"`）。`"metrotaipei"` 不匹配任何判斷，導致兩個 SVG 均不渲染，圖表顯示空白。
  - **`DistrictChart.vue`**：修正 `cityName` computed，改為查找 cities 陣列取出 `name` 顯示名；若找不到（空值或未知代碼）則 fallback 回 `"雙北市"`（對應最大範圍的 SVG，通用性最佳）。
  - **`ChatResultComponents.vue`**：在渲染 `DashboardComponent` 時補傳 `:active-city="primaryComponent.dashboardConfig?.city || ''"`，確保組件明確知道應顯示哪個城市的地圖，不再依賴 fallback。

- change-type:
  - Fixed

- technical-details:
  - **修改前的 `cityName`**：
    ```js
    if (!props.activeCity) return "metrotaipei"  // 回傳代碼，非顯示名
    return cities.find(city => city.value === props.activeCity)?.name
    ```
  - **修改後的 `cityName`**：
    ```js
    const found = cities.find(city => city.value === props.activeCity);
    return found?.name ?? "雙北市";  // 統一回傳顯示名
    ```
  - SVG 條件：`v-if="cityName === '新北市' || cityName === '雙北市'"` 與 `v-if="cityName === '臺北市'"` 現在都能正確命中
  - `city_age_distribution` 組件有 `taipei` 與 `metrotaipei` 兩個城市版本；傳入正確 `activeCity` 後會分別顯示臺北 12 區或雙北 41 區地圖

- verification:
  - VS Code 錯誤面板：兩個檔案均顯示「No errors found」
  - `DistrictChart.vue` 中 `cityName` 邏輯：`cities.find(...)?.name ?? "雙北市"` 完整取代原有邏輯
  - `ChatResultComponents.vue` 中 `:active-city` prop 已加入

- impact-risk:
  - **範圍**：DistrictChart 組件在所有地方的渲染。主要影響 ChatBot 右下角組件預覽卡片。
  - **儀表板主視圖影響**：儀表板中 DistrictChart 通過 `selectBtn` + `v-model` 控制 `activeCity`，不受此修改影響。
  - **Fallback 改為「雙北市」**：若有特殊路徑未傳 `activeCity` 且 `activeCity` 為空值，現在會顯示雙北 SVG 而非空白，比原本的空白行為更好。

- regression-test:
  - [ ] 查詢「全市年齡分區」→ ChatBot 應顯示行政區地圖（臺北市 12 區）
  - [ ] 查詢「雙北人口分布」→ 若有 metrotaipei 城市版本，應顯示雙北 41 區地圖
  - [ ] 儀表板主視圖 DistrictChart → 確認城市切換功能正常（不受影響）
  - [ ] DistrictChart activeCity = '' → 現在顯示雙北 SVG，不再空白

- traceability:
  - N/A

- next-actions:
  - N/A
