# 前端組件架構可視化

## 1. 組件層級關係樹 (Hierarchy)

```
Taipei-City-Dashboard-FE/
│
├── src/views/
│   ├── DashboardView.vue
│   │   ├── mode: "default" | "half"
│   │   ├── Props: selectBtn, favoriteBtn, deleteBtn, infoBtn
│   │   └── Emit: @favorite, @delete, @info, @change-city
│   │
│   ├── ComponentView.vue
│   │   ├── mode: "preview"
│   │   ├── Props: addBtn, favoriteBtn
│   │   └── Emit: @add, @favorite, @info
│   │
│   ├── MapView.vue
│   │   ├── mode: "map" | "halfmap"
│   │   ├── Props: toggleDisable, toggleOn
│   │   └── Emit: @toggle, @filter-by-param, @filter-by-layer, @fly
│   │
│   ├── ComponentInfoView.vue
│   │   ├── mode: "default"
│   │   └── 單一組件詳頁
│   │
│   └── EmbedView.vue
│       ├── mode: "default"
│       └── 嵌入式檢視
│
├── src/dashboardComponent/
│   │
│   ├── DashboardComponent.vue (核心)
│   │   ├── 【Header】
│   │   │   ├── 標題 (config.name)
│   │   │   ├── NEW 標籤 (isHackathonComponent)
│   │   │   ├── 更新頻率 Tag (ComponentTag)
│   │   │   └── 右上角按鈕
│   │   │       ├── addBtn → add_circle
│   │   │       ├── favoriteBtn → favorite (紅色)
│   │   │       ├── deleteBtn → delete
│   │   │       └── toggleOn (map mode)
│   │   │
│   │   ├── 【Control】
│   │   │   ├── selectBtn (城市選擇)
│   │   │   └── 圖表類型按鈕群
│   │   │       ├── BarChart 按鈕
│   │   │       ├── ColumnChart 按鈕
│   │   │       ├── ... (23 種)
│   │   │
│   │   ├── 【Content】動態載入
│   │   │   ├── BarChart.vue
│   │   │   ├── ColumnChart.vue
│   │   │   ├── TimelineStackedChart.vue
│   │   │   ├── DistrictChart.vue
│   │   │   ├── ... (其他 19 個)
│   │   │
│   │   ├── 【Footer】
│   │   │   ├── 功能標籤
│   │   │   │   ├── tune (篩選地圖)
│   │   │   │   ├── map (空間資料)
│   │   │   │   └── insights (歷史資料)
│   │   │   └── 資訊按鈕
│   │   │
│   │   └── 【Teleport】
│   │       └── TagTooltip.vue
│   │
│   ├── components/ (23 個圖表)
│   │   ├── 【時間序列】
│   │   │   ├── TimelineStackedChart.vue
│   │   │   ├── TimelineSeparateChart.vue
│   │   │   └── HistoryChart.vue
│   │   │
│   │   ├── 【地理分佈】
│   │   │   ├── DistrictChart.vue
│   │   │   ├── PolarAreaChart.vue
│   │   │   ├── HeatmapChart.vue
│   │   │   ├── MetroChart.vue
│   │   │   └── MetroCarDensity.vue
│   │   │
│   │   ├── 【柱形圖表】
│   │   │   ├── BarChart.vue
│   │   │   ├── ColumnChart.vue
│   │   │   ├── BarPercentChart.vue
│   │   │   ├── BarChartWithGoal.vue
│   │   │   └── ColumnLineChart.vue
│   │   │
│   │   ├── 【環形/指示】
│   │   │   ├── DonutChart.vue
│   │   │   ├── GuageChart.vue
│   │   │   ├── IconPercentChart.vue
│   │   │   ├── SpeedometerChart.vue
│   │   │   └── IndicatorChart.vue
│   │   │
│   │   ├── 【其他圖表】
│   │   │   ├── RadarChart.vue
│   │   │   ├── TreemapChart.vue
│   │   │   ├── TextUnitChart.vue
│   │   │   └── MapLegend.vue
│   │   │
│   │   └── 【UI 組件】
│   │       ├── ComponentTag.vue
│   │       └── TagTooltip.vue
│   │
│   ├── utilities/
│   │   ├── AllTimes.ts
│   │   ├── chartTypes.ts
│   │   ├── cityManager.ts
│   │   ├── componentConfig.ts
│   │   ├── dataTimeframe.ts
│   │   ├── districtCoordinates.ts
│   │   └── taipeiMetroLines.ts
│   │
│   ├── assets/
│   │   ├── chart/ (23 個 SVG 預覽)
│   │   └── backup_all_components.json
│   │
│   └── styles/
│       ├── chartStyles.css
│       └── toggleswitch.css
│
└── src/components/
    ├── dialogs/
    │   ├── MoreInfo.vue (🔍 放大檢視)
    │   │   ├── 左: DashboardComponent (mode="large")
    │   │   └── 右: 詳細資訊面板
    │   │
    │   ├── DialogContainer.vue
    │   ├── HistoryChart.vue
    │   ├── DownloadData.vue
    │   └── EmbedComponent.vue
    │
    └── utilities/
        ├── bars/
        ├── forms/
        └── miscellaneous/
```

---

## 2. 尺寸響應式分層

```
視口寬度 <1050px │ 1050-1649px │ 1650-2199px │ ≥2200px
────────────────┼─────────────┼─────────────┼─────────
Default mode    │             │             │
  330px         │    370px    │    400px    │  500px
                │             │             │
Half mode       │             │             │
  180px         │    210px    │    225px    │  275px
                │             │             │
Large mode      │             │             │
  350px         │    380px    │    420px    │  520px
```

**內部結構比例**:
```
┌──────────────────────────────────┐
│ Header: 10% 高度                 │ ← 固定 (包含標題、按鈕)
├──────────────────────────────────┤
│ Control: 10% 高度                │ ← 圖表選擇按鈕
├──────────────────────────────────┤
│ Chart: 75% 高度                  │ ← 主要內容區 (可滾動)
├──────────────────────────────────┤
│ Footer: 5% 高度                  │ ← 固定 (26px 確切值)
└──────────────────────────────────┘
```

---

## 3. 數據流向圖

```
User Input
    │
    ├─ 點擊圖表類型按鈕
    │   └─ changeActiveChart(name)
    │       └─ activeChart.value = name
    │           └─ <component :is="returnChartComponent(activeChart)">
    │
    ├─ 點擊最愛按鈕
    │   └─ @favorite(id) → DashboardView
    │       └─ contentStore.favoriteComponent(id)
    │
    ├─ 點擊詳細資訊按鈕
    │   └─ @info(config) → DashboardView
    │       └─ dialogStore.showMoreInfo(item)
    │           └─ MoreInfo.vue 彈出
    │
    ├─ 點擊城市選擇
    │   └─ activeCity (computed) 觸發 emit
    │       └─ @change-city(city) → DashboardView
    │           └─ contentStore.setComponentData(index, data)
    │
    └─ 切換地圖圖層 (map 模式)
        └─ toggleOn (computed) 觸發 emit
            └─ @toggle(value, map_config)
                └─ 更新 toggleOn 狀態
                    └─ CSS 類切換 (mapopen ↔ mapclosed)
```

---

## 4. 右上角按鈕動態配置

```
┌─────────────────────────────────────┐
│  DashboardComponent Header          │
└────────┬────────────────────────┬───┘
         │ 左側                   │ 右側 (.dashboardcomponent-header-button)
         │ ├─ 標題              │ ├─ [🔍] 全屏 (🎯 建議新增)
         │ ├─ NEW               │ ├─ [➕] 加入
         │ ├─ 更新頻率 Tag      │ ├─ [❤️] 最愛 (紅色)
         │ └─ 時間範圍          │ └─ [🗑️] 刪除

模式決定按鈕顯示:
┌───────────────┬────────┬──────────┬──────────┬────────┐
│ 視圖          │ addBtn │ favBtn   │ delBtn   │ toggle │
├───────────────┼────────┼──────────┼──────────┼────────┤
│ DashboardView │   ❌   │    ✅    │  ✅*     │   ❌   │
│ ComponentView │   ✅   │    ✅    │   ❌     │   ❌   │
│ MoreInfo      │   ❌   │    ❌    │   ❌     │   ❌   │
│ MapView       │   ❌   │    ❌    │   ❌     │   ✅   │
└───────────────┴────────┴──────────┴──────────┴────────┘
* 僅個人儀表板
```

---

## 5. Fullscreen / Modal 狀態機

```
┌──────────────────────────────────────┐
│      DEFAULT 模式                    │
│  ├─ 標準儀表板檢視 (mode: default)   │
│  ├─ 尺寸: 330-500px                 │
│  └─ ❌ 無全屏                        │
└──────────────────────────────────────┘
         ↓ (雙擊或按按鈕)
┌──────────────────────────────────────┐
│      MOREINFO MODAL (放大檢視)       │
│  ├─ 模式: mode="large"              │
│  ├─ 尺寸: 350-520px                 │
│  ├─ 背景: DialogContainer (z-index) │
│  ├─ 內容: 組件 + 詳細資訊面板       │
│  └─ 🎯 建議: 支援 Fullscreen API    │
└──────────────────────────────────────┘
         ↓ (點擊全屏按鈕 - 建議新增)
┌──────────────────────────────────────┐
│      FULLSCREEN 模式 (建議)          │
│  ├─ 尺寸: 100vw × 100vh             │
│  ├─ API: element.requestFullscreen() │
│  ├─ 退出: ESC 或按鈕                │
│  └─ ✅ 完全放大檢視                 │
└──────────────────────────────────────┘

地圖模式狀態轉換:
┌───────────────────────────┐
│ MAP 模式 (toggleOn: false)│
│ ├─ CSS: .mapclosed        │
│ ├─ 高度: fit-content      │
│ └─ 地圖: 摺疊             │
└────────────┬──────────────┘
             │ [Toggle ON]
             ↓
┌───────────────────────────┐
│ MAP 模式 (toggleOn: true) │
│ ├─ CSS: .mapopen          │
│ ├─ 高度: 330px            │
│ ├─ 圖表: 80%              │
│ └─ 地圖: 展開             │
└───────────────────────────┘
```

---

## 6. 圖表類型選擇流程

```
              ┌─────────────────────────┐
              │  Control Bar Buttons    │
              └────────────┬────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ↓                 ↓                 ↓
    BarChart         ColumnChart      TimelineStackedChart
   (水平條形)        (直立柱狀)         (時間軸堆疊)
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                 activeChart.value = name
                           │
                           ↓
        <component :is="returnChartComponent(activeChart)">
                           │
                ┌──────────┴──────────┐
                │                     │
                ↓                     ↓
          實時切換            SVG 預覽 (preview mode)
          (儀表板)           (組件庫)

returnChartComponent(name):
- 輸入: 圖表名稱 (string)
- 輸出: 組件引用或 SVG 路徑
- 總映射: 23 種圖表 + 1 個預設 (MapLegend)
```

---

## 7. 黑客松新組件標記位置

```
<h3>
  {{ config.name }}
  ┌───────────────────────────────────┐
  │ <span v-if="isHackathonComponent" │
  │   class="dashboardcomponent-new-badge">
  │   New
  │ </span>
  └───────────────────────────────────┘
</h3>

NEW 標籤樣式:
┌──────────────┐
│    New       │ ← margin-left: 8px
├──────────────┤   background: var(--color-highlight)
│ 字體: 85%    │   padding: 2px 6px
│ 顏色: 白     │   border-radius: 4px
│ 重量: 600    │
└──────────────┘

標籤組件列表 (8 個):
aed_map ✅
aed_district_tpe ✅
indigenous_district_tpe ✅
indigenous_group_tpe ✅
migrant_workers_tpe ✅
long_term_care_abc_map ✅
long_term_care_abc_district_tpe ✅
```

---

## 8. Props 與 Emits 快速對照

```
Props Flow (輸入):
DashboardView
  ├─ :config (必需)
  ├─ mode="default|half"
  ├─ :favorite-btn="true"
  ├─ :is-favorite="state"
  ├─ :select-btn="true"
  ├─ :select-btn-list="[]"
  ├─ :city-tag="[]"
  ├─ :delete-btn="true|false"
  └─ :info-btn="true"

Emits Flow (輸出):
DashboardComponent
  ├─ @favorite(id)
  ├─ @delete(id)
  ├─ @add(id, name)
  ├─ @info(config)
  ├─ @change-city(city)
  ├─ @toggle(value, map_config)
  ├─ @filter-by-param(...)
  ├─ @filter-by-layer(...)
  ├─ @clear-by-param-filter(...)
  ├─ @clear-by-layer-filter(...)
  └─ @fly(location)
```

---

## 9. CSS 類型與佈局類

```
主要容器類:
.dashboardcomponent          # 基礎容器
├─ .dashboardcomponent-header        # 標題區
├─ .dashboardcomponent-control       # 控制列
├─ .dashboardcomponent-chart         # 圖表區 (75%)
├─ .dashboardcomponent-footer        # 底部 (26px)
├─ .dashboardcomponent-loading       # 載入狀態
└─ .dashboardcomponent-error         # 錯誤狀態

模式類 (主要尺寸控制):
.large              # mode="large"   (350-520px)
.half               # mode="half"    (180-275px)
.halfmapopen        # halfmap 開啟   (200px)
.mapopen            # map 開啟       (330px)
.mapclosed          # map 關閉       (fit-content)
.preview            # mode="preview" (170px)

狀態類:
.isfavorite         # 已加入最愛 (紅色)
.isDelete           # 刪除按鈕狀態
.dashboardcomponent-new-badge  # NEW 標籤

内部元素類:
.dashboardcomponent-header-button   # 右上按鈕群
.dashboardcomponent-header-toggle   # 地圖開關
.dashboardcomponent-control-group   # 圖表按鈕群
.dashboardcomponent-control-group-active  # 活躍圖表
.city-tag-container             # 城市標籤容器
```

---

## 10. 文件結構樹 (完整路徑)

```
src/
├── dashboardComponent/
│   ├── DashboardComponent.vue (1100+ 行)
│   ├── components/
│   │   ├── BarChart.vue
│   │   ├── ColumnChart.vue
│   │   ├── TimelineStackedChart.vue
│   │   ├── TimelineSeparateChart.vue
│   │   ├── DistrictChart.vue
│   │   ├── DonutChart.vue
│   │   ├── TreemapChart.vue
│   │   ├── ColumnLineChart.vue
│   │   ├── BarPercentChart.vue
│   │   ├── GuageChart.vue
│   │   ├── RadarChart.vue
│   │   ├── MetroChart.vue
│   │   ├── HeatmapChart.vue
│   │   ├── PolarAreaChart.vue
│   │   ├── BarChartWithGoal.vue
│   │   ├── IconPercentChart.vue
│   │   ├── IndicatorChart.vue
│   │   ├── TextUnitChart.vue
│   │   ├── MapLegend.vue
│   │   ├── SpeedometerChart.vue
│   │   ├── MetroCarDensity.vue
│   │   ├── ComponentTag.vue
│   │   └── TagTooltip.vue
│   │
│   ├── utilities/
│   │   ├── AllTimes.ts
│   │   ├── chartTypes.ts
│   │   ├── cityManager.ts
│   │   ├── componentConfig.ts
│   │   ├── dataTimeframe.ts
│   │   ├── districtCoordinates.ts
│   │   └── taipeiMetroLines.ts
│   │
│   ├── assets/
│   │   └── chart/ (23 SVG files)
│   │
│   └── styles/
│       ├── chartStyles.css
│       └── toggleswitch.css
│
├── views/
│   ├── DashboardView.vue (200 行)
│   ├── ComponentView.vue (100 行)
│   ├── MapView.vue (500+ 行)
│   ├── ComponentInfoView.vue
│   └── EmbedView.vue
│
└── components/
    ├── dialogs/
    │   ├── MoreInfo.vue (150 行 - 📍 放大檢視)
    │   ├── DialogContainer.vue
    │   ├── HistoryChart.vue
    │   ├── DownloadData.vue
    │   └── EmbedComponent.vue
    │
    ├── utilities/
    │   ├── bars/
    │   ├── forms/
    │   └── miscellaneous/
    │
    └── charts/
        └── HistoryChart.vue
```

---

**說明**: 此頁面為可視化組件架構參考，配合詳細文檔使用。
