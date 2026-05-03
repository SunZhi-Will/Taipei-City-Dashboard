# Taipei-City-Dashboard-FE 組件架構深度分析

**分析日期**: 2026-04-17  
**範圍**: `src/dashboardComponent/` 完整組件體系與佈局策略

---

## 📐 1. DashboardComponent.vue 核心結構

### 1.1 組件模式（Mode）定義

`DashboardComponent.vue` 支援 **6 種佈局模式**：

| Mode | 尺寸 | 用途 | 響應式 |
|------|------|------|--------|
| `default` | 330px（桌面）/ 370px（1050px+）/ 400px（1650px+）/ 500px（2200px+） | 儀表板標準組件 | 4 層級 |
| `large` | 350px / 380px / 420px / 520px | 詳細資訊對話框 | 4 層級 |
| `map` | 330px（關閉）/ 100%（開啟） | 含地圖圖層的組件 | 動態 |
| `half` | 180px / 210px / 225px / 275px | 2 欄佈局用 | 4 層級 |
| `halfmap` | 200px（組件）+ 75% 圖表 | 半屏+地圖混合 | 動態 |
| `preview` | 170px 固定 | 組件庫預覽 | 無 |

### 1.2 組件 Props 完整清單

```javascript
// 佈局控制
style: Object                    // 自訂樣式
mode: String (validator)         // 上述 6 種模式

// 資料配置
config: Object (required)        // 組件配置（名稱、圖表、資料等）

// 右上角按鈕群組
selectBtn: Boolean              // 城市選擇下拉列表
selectBtnDisabled: Boolean      
selectBtnList: Array            // 選項列表
favoriteBtn: Boolean            // 加入最愛按鈕
isFavorite: Boolean             // 最愛狀態
deleteBtn: Boolean              // 刪除按鈕（個人儀表板）
addBtn: Boolean                 // 加入按鈕（組件庫）
infoBtn: Boolean                // 詳細資訊按鈕
infoBtnText: String             // 按鈕文字

// 地圖相關
toggleDisable: Boolean          // 禁用地圖開關
toggleOn: Boolean               // 地圖開啟狀態

// 樣式與標籤
cityTag: Array                  // 城市標籤
activeCity: String              // 當前城市
footer: Boolean (default: true) // 顯示底部
```

### 1.3 核心 Emits（事件發射）

```javascript
@favorite                   // 加入/移除最愛
@delete                     // 刪除組件
@add                        // 新增至儀表板
@info                       // 開啟詳細資訊
@toggle                     // 地圖開關切換
@filterByParam              // 按參數篩選地圖
@filterByLayer              // 按圖層篩選地圖
@clearByParamFilter         // 清除參數篩選
@clearByLayerFilter         // 清除圖層篩選
@fly                        // 地圖飛行到位置
@changeCity                 // 改變城市
```

---

## 🎨 2. 組件尺寸與佈局詳解

### 2.1 組件高度尺寸對照表

| 視口寬度 | default | large | half | halfmap | map |
|---------|---------|-------|------|---------|-----|
| < 1050px | 330px | 350px | 180px | 200px | 330px |
| 1050-1649px | 370px | 380px | 210px | 200px | 330px |
| 1650-2199px | 400px | 420px | 225px | 200px | 330px |
| ≥ 2200px | 500px | 520px | 275px | 200px | 330px |

### 2.2 內部佈局結構

```
┌─────────────────────────────────────────────────┐
│ .dashboardcomponent-header (Header Section)     │
│ ┌─────────────────┬──────────────────────────┐  │
│ │ 左側: 標題群組  │ 右側: 操作按鈕群組       │  │
│ │ - 名稱          │ - 加入(+)                │  │
│ │ - NEW 標籤      │ - 最愛(♥)               │  │
│ │ - 更新頻率Tag   │ - 刪除(X)               │  │
│ │ - 資料來源      │ - 地圖開關(Toggle)      │  │
│ │ - 時間範圍      │                          │  │
│ └─────────────────┴──────────────────────────┘  │
├─────────────────────────────────────────────────┤
│ .dashboardcomponent-control (控制列)           │
│ ┌────────────────────────────────────────────┐  │
│ │ 城市選擇 | [圖表1] [圖表2] [圖表3]...       │  │
│ └────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│ .dashboardcomponent-chart (內容區 75% 高)       │
│ ┌────────────────────────────────────────────┐  │
│ │ <component :is="activeChart">             │  │
│ │ 動態載入當前圖表組件                       │  │
│ └────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│ .dashboardcomponent-footer (底部 26px)         │
│ ┌─────────────────┬──────────────────────────┐  │
│ │ 篩選/地圖/歷史  │ 組件資訊按鈕            │  │
│ │ 標籤組          │                          │  │
│ └─────────────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 2.3 右上角操作按鈕區域詳解

**按鈕位置**: `.dashboardcomponent-header-button`

```vue
<!-- 標準儀表板模式 (mode: 'default' | 'half' | 'preview') -->
<div class="dashboardcomponent-header-button">
  <button v-if="addBtn">
    <span>add_circle</span>          <!-- 加入按鈕 -->
  </button>
  <button v-if="favoriteBtn" :class="{isfavorite: isFavorite}">
    <span>favorite</span>             <!-- 最愛按鈕 (紅色) -->
  </button>
  <button v-if="deleteBtn" class="isDelete">
    <span>delete</span>               <!-- 刪除按鈕 (僅個人儀表板) -->
  </button>
</div>

<!-- 地圖模式 (mode: 'map' | 'halfmap') -->
<div class="dashboardcomponent-header-toggle">
  <label class="toggleswitch">
    <input v-model="toggleOn" type="checkbox" :disabled="toggleDisable">
    <span class="toggleswitch-slider" />
  </label>
</div>
```

**按鈕樣式特性**：
- 圖標使用 Material Design Icons (`--font-icon`)
- 預設顏色: `var(--color-complement-text)` (灰色)
- 懸停效果: 轉為 `white`
- 最愛按鈕特殊: `rgb(255, 65, 44)` 紅色

---

## 🗂️ 3. dashboardComponent 資料夾架構

### 3.1 完整目錄樹狀結構

```
src/dashboardComponent/
├── DashboardComponent.vue (主容器組件)
│
├── components/             (23 個圖表與 UI 組件)
│   ├── 時間序列圖表
│   │   ├── TimelineSeparateChart.vue    (時間軸-分開)
│   │   ├── TimelineStackedChart.vue     (時間軸-堆疊)
│   │   └── HistoryChart.vue             (歷史時間軸)
│   │
│   ├── 面積/分佈圖表
│   │   ├── DistrictChart.vue            (行政區分布)
│   │   ├── PolarAreaChart.vue           (極座標面積圖)
│   │   ├── HeatmapChart.vue             (熱力圖)
│   │   └── MetroChart.vue               (捷運車次密度)
│   │   └── MetroCarDensity.vue          (捷運車廂密度)
│   │
│   ├── 柱/條形圖表
│   │   ├── BarChart.vue                 (水平條形圖)
│   │   ├── ColumnChart.vue              (直立柱狀圖)
│   │   ├── BarPercentChart.vue          (百分比水平條)
│   │   ├── BarChartWithGoal.vue         (含目標線的條形圖)
│   │   └── ColumnLineChart.vue          (柱線混合圖)
│   │
│   ├── 環形/指示圖表
│   │   ├── DonutChart.vue               (甜甜圈圖)
│   │   ├── GuageChart.vue               (表速計/儀錶盤)
│   │   ├── IconPercentChart.vue         (圖示百分比)
│   │   ├── SpeedometerChart.vue         (速度表)
│   │   └── IndicatorChart.vue           (指示燈)
│   │
│   ├── 其他圖表
│   │   ├── RadarChart.vue               (雷達圖)
│   │   ├── TreemapChart.vue             (樹狀圖)
│   │   ├── TextUnitChart.vue            (文字單位圖)
│   │   └── MapLegend.vue                (地圖圖例)
│   │
│   └── UI 組件
│       ├── ComponentTag.vue             (標籤組件)
│       └── TagTooltip.vue               (標籤提示)
│
├── utilities/              (業務邏輯與配置)
│   ├── AllTimes.ts                      (時間項定義)
│   ├── chartTypes.ts                    (圖表類型名稱對照)
│   ├── cityManager.ts                   (城市管理邏輯)
│   ├── componentConfig.ts               (組件配置工具)
│   ├── dataTimeframe.ts                 (時間幀計算)
│   ├── districtCoordinates.ts           (行政區座標)
│   └── taipeiMetroLines.ts              (捷運路線配置)
│
├── assets/                 (圖表預覽 SVG + 圖示)
│   ├── chart/              (23 個圖表類型的預覽 SVG)
│   │   ├── BarChart.svg
│   │   ├── TimelineStackedChart.svg
│   │   ├── ... (其他 20 個)
│   │   └── backup_all_components.json  (組件配置備份)
│   │
│   └── (其他資源)
│
└── styles/                 (全域樣式)
    ├── chartStyles.css     (圖表特殊樣式)
    └── (其他樣式檔)
```

### 3.2 組件層級關係圖

```
DashboardComponent.vue (容器)
│
├── Header Section
│   ├── 標題 + NEW 標籤 (hackathon 組件)
│   ├── ComponentTag (更新頻率)
│   └── 右上角按鈕群組
│
├── Control Section
│   ├── Select (城市選擇)
│   └── Chart Type Buttons (多圖表切換)
│
├── Content Section (動態)
│   └── <component :is="activeChart">
│       ├── BarChart.vue
│       ├── ColumnChart.vue
│       ├── TimelineStackedChart.vue
│       ├── MapLegend.vue
│       └── ... (其他 18 個圖表)
│
├── Loading/Error States
│   ├── .dashboardcomponent-loading (轉圈動畫)
│   └── .dashboardcomponent-error (組件資料異常)
│
├── Footer Section
│   ├── 功能標籤 (篩選/地圖/歷史)
│   └── 組件資訊按鈕
│
└── Teleport (DOM 尾部)
    └── TagTooltip (懸浮提示)
```

### 3.3 子組件用途速查表

| 組件名稱 | 圖表類型 | 輸入資料 | 互動功能 | 地圖支援 |
|---------|---------|--------|--------|---------|
| **BarChart** | 水平條形圖 | series (數值陣列) | 無 | ❌ |
| **ColumnChart** | 直立柱狀圖 | series | 無 | ❌ |
| **TimelineStackedChart** | 堆疊時間軸 | series (時間序列) | Drill-down | ✅ |
| **TimelineSeparateChart** | 分開時間軸 | series (多線) | 無 | ✅ |
| **DistrictChart** | 行政區分布 | series (按區域) | 點擊篩選 | ✅ |
| **DonutChart** | 甜甜圈圖 | series (類別) | 無 | ❌ |
| **RadarChart** | 雷達圖 | series (多維) | 無 | ❌ |
| **HeatmapChart** | 熱力圖 | series (格子資料) | 無 | ✅ |
| **MetroChart** | 捷運密度 | series (捷運線路) | 無 | ✅ |
| **GuageChart** | 儀錶盤 | series (單一指標) | 無 | ❌ |
| **IconPercentChart** | 圖示百分比 | series (整數比例) | 無 | ❌ |
| **MapLegend** | 地圖圖例 | map_config | 顯示層說明 | ✅ |
| **ComponentTag** | 標籤 UI | icon, text, mode | 無 | ❌ |
| **TreemapChart** | 樹狀圖 | series (層級) | 點擊展開 | ❌ |

---

## 🔍 4. 當前放大/縮放功能分析

### 4.1 現有放大/縮放實現方式

#### ✅ **已實現的放大**

1. **詳細資訊 Modal 對話框**
   - **實現方式**: `MoreInfo.vue` Dialog
   - **觸發**: 點擊 "組件資訊" 按鈕
   - **組件大小**: `mode="large"` (350-520px)
   - **特點**: 
     - 全螢幕 Modal 背景
     - 組件左側大視圖 + 右側詳細資訊
     - 含歷史圖表與資料連結

   ```vue
   <!-- DashboardView.vue & ComponentView.vue -->
   <DashboardComponent
     @info="(item) => {
       dialogStore.showMoreInfo(item);
     }"
   />
   ```

2. **地圖圖層切換**
   - **觸發方式**: 地圖模式下的 Toggle 開關
   - **模式轉換**: 
     - 關閉: `mapclosed` → 高度自適應
     - 開啟: `mapopen` → 固定 330px + 圖表 80% 高
   - **樣式類**: `.mapopen`, `.halfmapopen`

3. **ApexCharts 內建工具列**
   - **位置**: 圖表右上角（相對於 `.dashboardcomponent-chart`）
   - **功能**:
     - 🔍 Zoom
     - 📥 Download
     - ⟲ Reset
   - **CSS 控制**: `.apexcharts-zoom-icon { ... }`

#### ❌ **未實現的功能**

- ❌ **全屏放大** (Fullscreen API)
- ❌ **拖動改變尺寸** (Resize Handler)
- ❌ **嵌入式 Zoom 滑塊** (自訂縮放控制)
- ❌ **雙擊放大** (Double-click Zoom)

### 4.2 ApexCharts 內建工具列位置

```scss
/* chartStyles.css */
.apexcharts-zoom-icon {
  /* 工具列按鈕樣式 */
}

/* 工具列出現位置 */
.dashboardcomponent-chart .apexcharts-toolbar {
  position: absolute;
  right: 10px;
  top: 10px;
}
```

---

## 🪟 5. Fullscreen 與 Modal 狀態處理

### 5.1 當前 Modal 實現

#### **MoreInfo.vue** (主要擴展視圖)

```vue
<DialogContainer
  :dialog="`moreInfo`"
  @on-close="dialogStore.hideAllDialogs"
>
  <div class="moreinfo">
    <!-- 左側: 大型組件 -->
    <DashboardComponent
      :config="dialogStore.moreInfoContent"
      mode="large"  <!-- 固定模式 -->
    />
    
    <!-- 右側: 詳細資訊 -->
    <div class="moreinfo-info">
      <div class="moreinfo-info-data">
        <!-- 組件說明、使用情境、歷史圖表、相關資料 -->
      </div>
    </div>
  </div>
</DialogContainer>
```

**特性**:
- 基於 `DialogContainer` 包裝
- 不是原生全屏 API，而是帶半透明背景的 z-index 覆蓋層
- 可透過 ESC 鍵或點擊背景關閉

#### **DialogStore** (狀態管理)

```typescript
dialogStore.showMoreInfo(item)   // 開啟
dialogStore.hideAllDialogs()      // 關閉所有對話框
dialogStore.moreInfoContent       // 當前內容
```

### 5.2 Fullscreen 狀態切換邏輯

**地圖模式狀態機**:

```
DEFAULT 模式
    ↓ (無全屏)
    
MAP 模式
    ↓ [Toggle OFF]
    ├─ mapclosed (height: fit-content)
    │  └─ 組件正常顯示，地圖內容摺疊
    │
    └─ [Toggle ON]
       └─ mapopen (height: 330px)
          └─ 組件 + 地圖層同時顯示
          
HALFMAP 模式 (同步應用)
    ├─ halfmapopen (height: 200px)
    │  └─ 組件縮小，地圖層同步可見
```

**實現方式** (`DashboardComponent.vue`):

```vue
<template>
  <div
    :class="[
      {
        dashboardcomponent: true,
        mapclosed: mode.includes('map') && !toggleOn,
        mapopen: mode === 'map' && toggleOn,
        halfmapopen: mode === 'halfmap' && toggleOn,
        half: mode === 'half',
        large: mode === 'large',
        preview: mode === 'preview',
      },
    ]"
  />
</template>

<script>
const toggleOn = computed({
  get: () => props.toggleOn,
  set: (value) => {
    emits("toggle", value, props.config.map_config);
  },
});
</script>
```

### 5.3 尺寸變化流程圖

```
┌─────────────────────────────────────────┐
│ Modal 開啟 (MoreInfo)                   │
│ dialogStore.showMoreInfo(item)          │
└──────────────────┬──────────────────────┘
                   ↓
     ┌──────────────────────────────┐
     │ 背景變暗 + z-index: 1000+   │
     │ 內容居中顯示                │
     └──────────────────┬───────────┘
                        ↓
     ┌──────────────────────────────┐
     │ mode="large" 套用            │
     │ 高度: 420px-520px            │
     │ 寬度: 100% (Dialog 容器)     │
     └──────────────────┬───────────┘
                        ↓
     ┌──────────────────────────────┐
     │ 圖表進行細部展示             │
     │ 底部顯示詳細資訊區段         │
     └──────────────────┬───────────┘
                        ↓
     ┌──────────────────────────────┐
     │ ESC 或點擊背景               │
     │ dialogStore.hideAllDialogs() │
     └─────────────────────────────┘
```

---

## 🎛️ 6. 右上角操作按鈕詳細規格

### 6.1 按鈕排列位置

**CSS 選擇器**: `.dashboardcomponent-header-button`

```scss
.dashboardcomponent-header-button {
  min-width: 48px;
  display: flex;
  justify-content: flex-end;
  align-items: flex-start;
  
  button span {
    color: var(--color-complement-text);          // 灰色
    font-family: var(--font-icon);                // Material Icons
    font-size: calc(var(--font-l) * var(--font-to-icon));
    transition: color 0.2s;
  }
  
  button:hover span {
    color: white;                                  // 懸停時轉白
  }
  
  button.isfavorite span {
    color: rgb(255, 65, 44);                      // 紅色
  }
}
```

### 6.2 按鈕群組配置

#### **標準模式 (default/half/preview)**

```vue
<div class="dashboardcomponent-header-button">
  <!-- 加入按鈕 (add_circle) -->
  <button v-if="addBtn" @click="$emit('add', config.id, config.name)">
    <span>add_circle</span>
  </button>
  
  <!-- 最愛按鈕 (favorite/heart) -->
  <button
    v-if="favoriteBtn"
    :class="{ isfavorite: isFavorite }"
    @click="$emit('favorite', config.id)"
  >
    <span>favorite</span>
  </button>
  
  <!-- 刪除按鈕 (delete/trash) -->
  <button
    v-if="deleteBtn"
    class="isDelete"
    @click="$emit('delete', config.id)"
  >
    <span>delete</span>
  </button>
</div>
```

**按鈕顯示邏輯**:

| 場景 | addBtn | favoriteBtn | deleteBtn |
|------|--------|------------|-----------|
| 儀表板組件 (DashboardView) | ❌ | ✅ (有登入) | ✅ (個人儀表板) |
| 組件庫預覽 (ComponentView) | ✅ | ✅ | ❌ |
| 詳細資訊 Modal | ❌ | ❌ | ❌ |

#### **地圖模式 (map/halfmap)**

```vue
<div class="dashboardcomponent-header-toggle">
  <label class="toggleswitch">
    <input
      v-model="toggleOn"
      type="checkbox"
      :disabled="toggleDisable"
    >
    <span class="toggleswitch-slider" />
  </label>
</div>
```

### 6.3 按鈕樣式詳細參數

| 屬性 | 數值 | 說明 |
|------|------|------|
| **字體** | `var(--font-icon)` | Material Design Icons |
| **預設顏色** | `var(--color-complement-text)` | 主題灰色 (通常 #999) |
| **懸停顏色** | `white` | 亮白色 |
| **最愛顏色** | `rgb(255, 65, 44)` | 活躍紅色 |
| **動畫** | `transition: color 0.2s` | 平滑過渡 |
| **最小寬度** | `48px` | Material Design 標準 |
| **對齐方式** | `flex-end` | 靠右對齐 |

### 6.4 按鈕響應式設計

```scss
@media (max-width: 760px) {
  button.isDelete { display: none !important; }  // 手機隱藏刪除
}

@media (min-width: 760px) {
  button.isFlag { display: none !important; }    // 桌面隱藏旗標
}

@media (min-width: 759px) {
  button.isUnfavorite { display: none !important; }
}
```

---

## 📊 7. 黑客松新組件標記

### 7.1 "New" 標籤實現

```vue
<!-- DashboardComponent.vue -->
<h3>
  {{ config.name }}
  <span v-if="isHackathonComponent" class="dashboardcomponent-new-badge">
    New
  </span>
</h3>

<script>
const HACKATHON_COMPONENT_INDEXES = new Set([
  "aed_map",
  "aed_district_tpe",
  "indigenous_district_tpe",
  "indigenous_group_tpe",
  "migrant_workers_tpe",
  "long_term_care_abc_map",
  "long_term_care_abc_district_tpe",
]);

const isHackathonComponent = computed(() => {
  return HACKATHON_COMPONENT_INDEXES.has(props.config.index);
});
</script>

<style scoped>
.dashboardcomponent-new-badge {
  display: inline-block;
  margin-left: 8px;
  padding: 2px 6px;
  border-radius: 4px;
  background-color: var(--color-highlight);
  color: #fff;
  font-size: calc(var(--font-s) * 0.85);
  font-weight: 600;
  letter-spacing: 0.03em;
  line-height: 1.4;
  font-family: inherit;
  user-select: none;
}
</style>
```

**特性**:
- 位置: 標題右側
- 顏色: `var(--color-highlight)` (通常橙色/紅色)
- 尺寸: 稍小於主標題字體
- 陰影: 無

### 7.2 黑客松組件清單 (8 個)

```javascript
HACKATHON_COMPONENT_INDEXES = [
  "aed_map",                          // AED 地圖
  "aed_district_tpe",                 // AED 按區域分佈
  "indigenous_district_tpe",          // 原住民族按區域
  "indigenous_group_tpe",             // 原住民族群體
  "migrant_workers_tpe",              // 移工分佈
  "long_term_care_abc_map",           // 長期照護地圖
  "long_term_care_abc_district_tpe",  // 長期照護按區域
]
```

---

## 🎯 8. 組件樹完整結構圖

```
src/
├── views/
│   ├── DashboardView.vue (主儀表板展示)
│   │   └── DashboardComponent.vue (mode="default" | "half")
│   │
│   ├── ComponentView.vue (組件庫)
│   │   └── DashboardComponent.vue (mode="preview")
│   │
│   ├── ComponentInfoView.vue (單一組件詳頁)
│   │   └── DashboardComponent.vue (mode="large")
│   │
│   ├── MapView.vue (地圖儀表板)
│   │   ├── DashboardComponent.vue (mode="map" | "halfmap")
│   │   └── [地圖互動邏輯]
│   │
│   └── EmbedView.vue (嵌入式組件)
│       └── DashboardComponent.vue (mode="default")
│
├── components/
│   ├── dialogs/
│   │   ├── MoreInfo.vue (詳細資訊 Modal - mode="large")
│   │   ├── DialogContainer.vue (基底 Modal 框架)
│   │   ├── HistoryChart.vue (歷史時間軸)
│   │   ├── DownloadData.vue
│   │   └── EmbedComponent.vue
│   │
│   ├── utilities/
│   │   ├── bars/ (控制列類組件)
│   │   │   └── SettingsBar.vue (等)
│   │   ├── forms/ (表單類組件)
│   │   └── miscellaneous/
│   │
│   └── charts/
│       └── HistoryChart.vue (時間軸圖表)
│
└── dashboardComponent/
    ├── DashboardComponent.vue (核心容器)
    │
    ├── components/
    │   ├── [23 個圖表組件]
    │   ├── ComponentTag.vue
    │   └── TagTooltip.vue
    │
    ├── utilities/
    │   ├── AllTimes.ts
    │   ├── chartTypes.ts
    │   ├── cityManager.ts
    │   ├── componentConfig.ts
    │   ├── dataTimeframe.ts
    │   ├── districtCoordinates.ts
    │   └── taipeiMetroLines.ts
    │
    ├── assets/
    │   ├── chart/ (23 個預覽 SVG)
    │   └── backup_all_components.json
    │
    └── styles/
        ├── chartStyles.css
        └── toggleswitch.css
```

---

## 📋 9. 實作建議清單

### 9.1 當前缺口與優化機會

| 功能 | 優先級 | 工作量 | 備註 |
|------|--------|--------|------|
| ✅ **詳細資訊 Modal** | P0 | 已實現 | 使用 DialogContainer |
| ✅ **地圖層切換** | P0 | 已實現 | 透過 toggleOn |
| ✅ **圖表類型切換** | P0 | 已實現 | 動態元件載入 |
| ✅ **最愛/收藏** | P0 | 已實現 | Pinia 狀態 |
| ❌ **全屏 API** | P1 | 中 | 添加原生全屏功能 |
| ❌ **自訂縮放滑塊** | P2 | 中 | ApexCharts 配置 |
| ❌ **拖動改尺寸** | P2 | 高 | 需要複雜事件處理 |
| ❌ **雙擊放大** | P2 | 低 | 在 Modal 中實現 |
| ✅ **響應式設計** | P0 | 已實現 | 4 層級視口 |
| ✅ **黑客松標籤** | P1 | 已實現 | 8 個組件已標記 |

### 9.2 擴展 Fullscreen 功能的建議步驟

```
1. 新增 Props
   - fullscreenBtn: Boolean (控制全屏按鈕顯示)
   - onFullscreen: Function (回調函式)

2. 添加按鈕到 header
   - 位置: 右上角按鈕群組前
   - 圖標: 'fullscreen'
   
3. 實現 Fullscreen API
   - 使用 element.requestFullscreen()
   - 處理瀏覽器兼容性
   
4. 樣式適配
   - CSS :fullscreen 偽類
   - 調整 Modal 在全屏時的尺寸

5. 事件處理
   - ESC 退出全屏
   - 鍵盤快捷鍵 (F11)
```

---

## 🔗 10. 關鍵檔案路徑速查

| 用途 | 檔案 | 行數 |
|------|------|------|
| 主容器 | [DashboardComponent.vue](DashboardComponent.vue) | ~1100 |
| 詳細資訊 Modal | [src/components/dialogs/MoreInfo.vue](../../components/dialogs/MoreInfo.vue) | ~150 |
| 對話框容器 | [DialogContainer.vue](../../components/dialogs/DialogContainer.vue) | - |
| 儀表板檢視 | [src/views/DashboardView.vue](../../views/DashboardView.vue) | ~200 |
| 組件庫檢視 | [src/views/ComponentView.vue](../../views/ComponentView.vue) | ~100 |
| 地圖檢視 | [src/views/MapView.vue](../../views/MapView.vue) | ~500+ |
| 圖表樣式 | [assets/styles/chartStyles.css](assets/styles/chartStyles.css) | - |
| 城市管理 | [utilities/cityManager.ts](utilities/cityManager.ts) | ~120 |

---

## 📌 總結

### 核心架構特性
✅ **6 種模式**: 靈活適應不同佈局需求  
✅ **23 種圖表**: 全面覆蓋資料視覺化需求  
✅ **模態對話框**: 透過 Modal 實現詳細檢視  
✅ **地圖層機制**: 透過 toggle 控制地圖顯示  
✅ **響應式設計**: 4 層級視口適配  
✅ **黑客松支援**: 8 個新組件已標記  

### 現有放大/全屏方案
1. **MoreInfo Modal** (mode="large") - 推薦方案
2. **ApexCharts 內建工具列** - 圖表級別
3. **地圖層切換** - 組件級別

### 建議優化方向
🎯 **P0**: 無 (架構完善)  
🎯 **P1**: 添加 Fullscreen API、優化按鈕排列  
🎯 **P2**: 自訂縮放控制、拖動改尺寸

---

**報告編制**: GitHub Copilot 深度分析  
**最後更新**: 2026-04-17  
**版本**: 1.0
