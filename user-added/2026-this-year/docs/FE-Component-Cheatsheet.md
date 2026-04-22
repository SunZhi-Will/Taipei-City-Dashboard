# 前端組件架構 - 快速參考卡 (Cheat Sheet)

## 1️⃣ 六種模式對照

```
┌─────────────┬──────────┬──────────┬────────────┬──────────────┬─────────────┐
│ Mode        │ 預設高度 │ 用途     │ 視圖位置   │ 按鈕群       │ 是否全屏    │
├─────────────┼──────────┼──────────┼────────────┼──────────────┼─────────────┤
│ default     │ 330-500px│ 標準儀表板│ DashboardView │ add/fav/del │ ❌        │
│ large       │ 350-520px│ 詳細資訊 │ MoreInfo   │ 無           │ ⚠️ Modal  │
│ map         │ 330px    │ 地圖層   │ MapView    │ Toggle開關   │ ⚠️ 條件  │
│ half        │ 180-275px│ 2欄佈局  │ DashboardView│ add/fav/del │ ❌        │
│ halfmap     │ 200px    │ 半屏地圖 │ MapView    │ Toggle開關   │ ⚠️ 條件  │
│ preview     │ 170px    │ 組件庫   │ ComponentView│ add/fav    │ ❌        │
└─────────────┴──────────┴──────────┴────────────┴──────────────┴─────────────┘
```

## 2️⃣ 右上角按鈕配置矩陣

```javascript
// 按鈕 Props 檢查清單
props = {
  addBtn:        Boolean,       // 加入按鈕 (add_circle)
  favoriteBtn:   Boolean,       // 最愛按鈕 (favorite) - 紅色
  deleteBtn:     Boolean,       // 刪除按鈕 (delete) - 僅個人儀表板
  selectBtn:     Boolean,       // 城市選擇下拉列表
  infoBtn:       Boolean,       // 詳細資訊按鈕 (footer)
  toggleDisable: Boolean,       // 地圖開關禁用
}

// 每種視圖的組合
DashboardView       → add:❌ fav:✅ del:✅ select:✅ toggle:❌
ComponentView       → add:✅ fav:✅ del:❌ select:❌ toggle:❌
MoreInfo Modal      → add:❌ fav:❌ del:❌ select:❌ toggle:❌
MapView (map mode)  → add:❌ fav:❌ del:❌ select:❌ toggle:✅
```

## 3️⃣ 圖表組件速查 (23 種)

### 時間序列 (3)
```
TimelineStackedChart  → 堆疊時間軸 (如累積確診數)
TimelineSeparateChart → 分開時間軸 (如多線對比)
HistoryChart         → 詳細歷史軸 (MoreInfo 專用)
```

### 地理/分佈 (5)
```
DistrictChart   → 行政區分布圖 (台北市各區)
PolarAreaChart  → 極座標面積圖
HeatmapChart    → 熱力圖 (強度分佈)
MetroChart      → 捷運車次密度
MetroCarDensity → 捷運車廂密度
```

### 柱形/條形 (5)
```
BarChart             → 水平條形圖
ColumnChart          → 直立柱狀圖
BarPercentChart      → 百分比水平條
BarChartWithGoal     → 條形圖 + 目標線
ColumnLineChart      → 柱線混合圖
```

### 環形/指示 (5)
```
DonutChart       → 甜甜圈圖 (類別佔比)
GuageChart       → 表速計/儀錶盤 (單值)
IconPercentChart → 圖示百分比 (如滿意度)
SpeedometerChart → 速度表
IndicatorChart   → 指示燈 (狀態燈)
```

### 其他 (5)
```
RadarChart       → 雷達圖 (多維對比)
TreemapChart     → 樹狀圖 (層級結構)
TextUnitChart    → 純文字單位圖
MapLegend        → 地圖圖例
```

## 4️⃣ Props 傳入範例

```vue
<!-- 標準儀表板組件 -->
<DashboardComponent
  :config="item"                              <!-- 必需 -->
  mode="default"
  :favorite-btn="true"
  :is-favorite="contentStore.favorites?.components.includes(item.id)"
  :select-btn="true"
  :select-btn-list="cityManager.getSelectList(item.city)"
  :city-tag="cityManager.getTagList(item.city)"
  @favorite="toggleFavorite(id)"
  @info="handleMoreInfo(item)"
  @change-city="(city) => { ... }"
/>

<!-- 詳細資訊 Modal -->
<DashboardComponent
  :config="dialogStore.moreInfoContent"
  mode="large"
  :active-city="dialogStore.moreInfoContent.city"
/>

<!-- 地圖模式 -->
<DashboardComponent
  :config="item"
  mode="map"
  :toggle-on="toggleState"
  @toggle="(value) => { ... }"
  @filter-by-param="..."
  @filter-by-layer="..."
/>
```

## 5️⃣ Emit 事件速查

```javascript
// 基本互動
@favorite                          // (id) - 加入/移除最愛
@delete                            // (id) - 刪除組件
@add                               // (id, name) - 新增至儀表板
@info                              // (config) - 開啟詳細資訊
@change-city                       // (city) - 切換城市

// 地圖篩選
@filter-by-param                   // (filter, config, x, y)
@filter-by-layer                   // (config, x)
@clear-by-param-filter             // (config)
@clear-by-layer-filter             // (config)
@fly                               // (location) - 飛行到位置
@toggle                            // (value, map_config)
```

## 6️⃣ CSS 類型速查

```scss
// 主容器類
.dashboardcomponent               // 基底
.dashboardcomponent-header        // 標題區
.dashboardcomponent-header-button // 右上角按鈕群
.dashboardcomponent-header-toggle // 地圖開關
.dashboardcomponent-control       // 圖表選擇列
.dashboardcomponent-chart         // 圖表內容區 (75% 高)
.dashboardcomponent-footer        // 底部區
.dashboardcomponent-loading       // 載入狀態
.dashboardcomponent-error         // 錯誤狀態

// 模式類
.large                            // mode="large"
.half                             // mode="half"
.halfmapopen                      // mode="halfmap" && toggleOn
.mapopen                          // mode="map" && toggleOn
.mapclosed                        // mode="map" && !toggleOn
.preview                          // mode="preview"

// 特殊類
.dashboardcomponent-new-badge     // New 標籤 (黑客松組件)
.isfavorite                       // 最愛按鈕 (紅色)
.isDelete                         // 刪除按鈕
.componenttag                     // 標籤組件
.componenttag-fill                // 填充標籤
.componenttag-small               // 小尺寸標籤
```

## 7️⃣ 黑客松新組件 (8 個)

```javascript
const HACKATHON_INDEXES = [
  "aed_map",                      // AED 地圖 🆕
  "aed_district_tpe",             // AED 區域分布 🆕
  "indigenous_district_tpe",      // 原住民族區域 🆕
  "indigenous_group_tpe",         // 原住民族群體 🆕
  "migrant_workers_tpe",          // 移工分布 🆕
  "long_term_care_abc_map",       // 長照地圖 🆕
  "long_term_care_abc_district_tpe", // 長照區域 🆕
]

// 觸發 New 標籤的邏輯
v-if="isHackathonComponent"
  <span class="dashboardcomponent-new-badge">New</span>
```

## 8️⃣ 顏色與圖示

```javascript
// 按鈕圖示 (Material Design Icons)
add_circle          // 加入
favorite            // 最愛 (紅色: rgb(255, 65, 44))
delete              // 刪除
arrow_circle_right  // 箭頭
map                 // 地圖
tune                // 篩選
insights            // 歷史資料

// CSS 變數
--color-normal-text       // 正文顏色
--color-complement-text   // 補充文字 (灰色)
--color-highlight         // 強調色 (橙/紅)
--color-component-background  // 組件背景
```

## 9️⃣ 常見實作模式

### 開啟詳細資訊
```vue
@info="(item) => {
  if (isMobileDevice) {
    router.push({ name: 'component-info', params: { index: item.index } });
  } else {
    dialogStore.showMoreInfo(item);
  }
}"
```

### 切換城市
```vue
@change-city="(city) => {
  const selectedData = contentStore.cityDashboard.components.find(
    (data) => data.index === item.index && data.city === city
  );
  if (selectedData) {
    contentStore.setComponentData(componentIndex, selectedData);
  }
}"
```

### 切換圖表類型
```javascript
function changeActiveChart(chartName) {
  if (props.mode === "map" && props.config.map_filter) {
    // 清除地圖篩選
    if (props.config.map_filter.mode === "byParam") {
      emits("clearByParamFilter", props.config.map_config);
    }
  }
  activeChart.value = chartName;
}
```

## 🔟 響應式斷點

```scss
/* 預設 (< 1050px) */
height: 330px;

/* Tablet (1050-1649px) */
@media (min-width: 1050px) { height: 370px; }

/* Desktop (1650-2199px) */
@media (min-width: 1650px) { height: 400px; }

/* UHD (≥ 2200px) */
@media (min-width: 2200px) { height: 500px; }

/* Mobile 按鈕隱藏 */
@media (max-width: 760px) {
  button.isDelete { display: none !important; }
}
```

---

**提示**: 列印此卡片可用於開發參考！
