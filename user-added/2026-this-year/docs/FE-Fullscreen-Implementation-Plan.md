# 前端組件放大/全屏功能擴展計畫

**文檔日期**: 2026-04-17  
**優先級**: P1 (建議優化)  
**工作量評估**: 2-3 天 (包含測試)  
**涉及模塊**: DashboardComponent.vue, MoreInfo.vue, 樣式層

---

## 📋 1. 需求分析

### 1.1 現狀評估

| 功能 | 當前實現 | 評估 |
|------|--------|------|
| **詳細資訊擴展** | ✅ Modal (mode="large") | 運作良好，500px 高度 |
| **地圖層切換** | ✅ Toggle + CSS 類 | 運作良好 |
| **圖表內縮放** | ✅ ApexCharts 工具列 | 運作良好 (zoom/download) |
| **原生全屏 API** | ❌ 未實現 | **優先補充** |
| **雙擊放大** | ❌ 未實現 | 建議考慮 |
| **自訂縮放滑塊** | ❌ 未實現 | 備選方案 |
| **拖動改變尺寸** | ❌ 未實現 | 複雜度高，暫不建議 |

### 1.2 用戶需求

```
用戶痛點:
❌ 某些圖表太小，難以看清細節
❌ 想單獨檢視一個組件，不看其他儀表板
❌ 無法全屏展示組件用於演示/投影

建議解決方案:
✅ 添加「全屏」按鈕
✅ 簡化 Modal 設計（移除側邊欄）
✅ 保留縮放工具列（ApexCharts 原有）
```

---

## 🎯 2. 實施方案（分層優先級）

### **第一層: 基礎全屏 API（P0 - 必做）**

#### 2.1.1 新增 Props

```javascript
// DashboardComponent.vue
defineProps({
  // ... 現有 props
  fullscreenBtn: {
    type: Boolean,
    default: false  // 預設不顯示
  }
});

// 新增 Emit
defineEmits([
  // ... 現有 emits
  "fullscreen"  // 當點擊全屏按鈕時觸發
]);
```

#### 2.1.2 更新模板 (Header 按鈕)

```vue
<!-- DashboardComponent.vue -->
<template>
  <div :class="[...]">
    <div class="dashboardcomponent-header">
      <div>
        <!-- 標題區保持不變 -->
      </div>
      
      <!-- 右上角按鈕群組 -->
      <div
        v-if="['default', 'half', 'preview'].includes(mode)"
        class="dashboardcomponent-header-button"
      >
        <!-- 全屏按鈕 (新) -->
        <button
          v-if="fullscreenBtn"
          class="fullscreen-btn"
          @click="toggleFullscreen"
          title="全屏檢視"
        >
          <span>{{ isFullscreen ? 'fullscreen_exit' : 'fullscreen' }}</span>
        </button>
        
        <!-- 現有按鈕 -->
        <button v-if="addBtn" @click="$emit('add', ...)">
          <span>add_circle</span>
        </button>
        <!-- ... 其他按鈕 -->
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";

const isFullscreen = ref(false);

function toggleFullscreen() {
  const element = document.querySelector('.dashboardcomponent-fullscreen-container');
  
  if (!document.fullscreenElement) {
    // 進入全屏
    element.requestFullscreen().catch((err) => {
      console.error(`全屏請求失敗: ${err.message}`);
    });
    isFullscreen.value = true;
  } else {
    // 退出全屏
    document.exitFullscreen();
    isFullscreen.value = false;
  }
  
  $emit("fullscreen", isFullscreen.value);
}

// 監聽全屏狀態變化
document.addEventListener('fullscreenchange', () => {
  isFullscreen.value = !!document.fullscreenElement;
});
</script>
```

#### 2.1.3 添加全屏容器包裝

```vue
<!-- DashboardComponent.vue - 模板修改 -->
<template>
  <!-- 新增容器用於全屏 -->
  <div
    class="dashboardcomponent-fullscreen-container"
    :class="{ 'is-fullscreen': isFullscreen }"
  >
    <div
      :class="[
        {
          dashboardcomponent: true,
          // ... 現有類
        },
      ]"
      :style="style"
    >
      <!-- 保持現有結構 -->
    </div>
  </div>
</template>
```

#### 2.1.4 全屏樣式

```scss
/* DashboardComponent.vue <style> 或 chartStyles.css */

.dashboardcomponent-fullscreen-container {
  &.is-fullscreen {
    /* 全屏時的樣式 */
    .dashboardcomponent {
      width: 100vw !important;
      height: 100vh !important;
      max-width: 100vw !important;
      max-height: 100vh !important;
      border-radius: 0 !important;
      
      .dashboardcomponent-chart {
        height: 85% !important;
      }
    }
  }
}

/* 全屏按鈕樣式 */
.fullscreen-btn {
  position: relative;
  z-index: 100;
  
  span {
    color: var(--color-complement-text);
    font-family: var(--font-icon);
    transition: color 0.2s;
  }
  
  &:hover span {
    color: white;
  }
}

/* 全屏時隱藏 UI 元素 (可選) */
:fullscreen {
  background: var(--color-component-background);
  
  .dashboardcomponent-header {
    /* 簡化 header */
    padding: 12px 16px;
  }
}
```

#### 2.1.5 使用範例

```vue
<!-- DashboardView.vue -->
<DashboardComponent
  :config="item"
  mode="default"
  :fullscreen-btn="true"        <!-- 新增 -->
  @fullscreen="(isFullscreen) => {
    console.log('全屏狀態:', isFullscreen);
  }"
/>

<!-- MoreInfo.vue -->
<DashboardComponent
  :config="dialogStore.moreInfoContent"
  mode="large"
  :fullscreen-btn="true"        <!-- 支援 Modal 中全屏 -->
/>
```

---

### **第二層: 增強型全屏 (P1 - 建議)**

#### 2.2.1 雙擊全屏

```javascript
// DashboardComponent.vue
function handleDblClick() {
  if (fullscreenBtn.value) {
    toggleFullscreen();
  }
}

// 模板
<div
  class="dashboardcomponent-fullscreen-container"
  @dblclick="handleDblClick"
>
```

#### 2.2.2 ESC 自動退出

```javascript
// 已由瀏覽器自動處理，無需額外程式碼
// 但可添加事件監聽確保狀態同步
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && isFullscreen.value) {
    isFullscreen.value = false;
    // 更新 UI
  }
});
```

#### 2.2.3 全屏時鍵盤快捷鍵

```javascript
// 在全屏容器中添加快捷鍵
document.addEventListener('keydown', (e) => {
  if (!isFullscreen.value) return;
  
  switch(e.key) {
    case 'z':  // Z 鍵放大
      if (window.apexcharts) {
        window.apexcharts.zoomIn();
      }
      break;
    case 'r':  // R 鍵重設
      if (window.apexcharts) {
        window.apexcharts.resetSeries();
      }
      break;
    case 'Escape':  // ESC 退出全屏
      toggleFullscreen();
      break;
  }
});
```

---

### **第三層: 簡化 Modal 版本 (P2 - 優化)**

#### 2.3.1 移除側邊欄的全屏模式

```vue
<!-- MoreInfo.vue - 添加全屏樣式 -->
<template>
  <DialogContainer :dialog="`moreInfo`" @on-close="...">
    <div :class="{'moreinfo': true, 'moreinfo-fullscreen': isFullscreenMode}">
      <DashboardComponent
        :config="dialogStore.moreInfoContent"
        mode="large"
        :fullscreen-btn="true"
        @fullscreen="(value) => { isFullscreenMode = value; }"
      />
      
      <!-- 側邊欄 - 全屏時隱藏 -->
      <div v-if="!isFullscreenMode" class="moreinfo-info">
        <!-- 詳細資訊 -->
      </div>
    </div>
  </DialogContainer>
</template>

<script setup>
const isFullscreenMode = ref(false);
</script>

<style>
.moreinfo {
  display: flex;
  
  &-fullscreen {
    .moreinfo-info {
      display: none !important;
    }
  }
}
</style>
```

---

## 🔧 3. 實施步驟 (Day-by-Day)

### **Day 1: 基礎實現**

- [ ] **08:00-09:00** 
  - 分析現有 DashboardComponent.vue 的結構
  - 準備備份

- [ ] **09:00-11:00**
  - 新增 fullscreenBtn Props 與 Emit
  - 實現 toggleFullscreen() 函式
  - 添加全屏容器包裝

- [ ] **11:00-12:00**
  - 添加基礎全屏樣式
  - 本地測試（Chrome, Firefox, Safari）

- [ ] **13:00-14:00**
  - 處理瀏覽器兼容性 (webkit-, moz-)
  - 測試 ESC 退出

- [ ] **14:00-15:00**
  - 更新 DashboardView 與 ComponentView 使用示例
  - 代碼審查

### **Day 2: 增強與優化**

- [ ] **08:00-10:00**
  - 實現雙擊全屏
  - 添加全屏時的 UI 簡化 (隱藏控制列等)

- [ ] **10:00-12:00**
  - 測試 Modal 中全屏功能
  - 修復層級衝突 (z-index)

- [ ] **13:00-15:00**
  - 效能測試（大型圖表）
  - 響應式測試（移動設備模擬）

### **Day 3: 測試與文檔**

- [ ] **08:00-11:00**
  - 完整回歸測試
  - 修復邊界案例

- [ ] **11:00-12:00**
  - 撰寫變更日誌
  - 代碼註解

- [ ] **13:00-15:00**
  - 更新文檔
  - 預發佈檢查

---

## 🧪 4. 測試計畫

### 4.1 功能測試矩陣

| 場景 | 測試項目 | 預期結果 | 狀態 |
|------|--------|---------|------|
| 點擊全屏按鈕 | 進入全屏 | 組件占滿整個屏幕 | ⬜ |
| 雙擊組件 | 進入全屏 | 組件占滿整個屏幕 | ⬜ |
| 按 ESC | 退出全屏 | 恢復到上一個狀態 | ⬜ |
| 按 F11 | 瀏覽器全屏 | 協調運作 | ⬜ |
| 圖表縮放 | ApexCharts 工具列 | 在全屏中可用 | ⬜ |
| 地圖圖層 | 地圖模式全屏 | 地圖層可交互 | ⬜ |
| Modal 全屏 | MoreInfo 組件 | 側邊欄隱藏 | ⬜ |
| 響應式退出 | 手機旋轉時 | 自動適配 | ⬜ |

### 4.2 瀏覽器兼容性

```
✅ Chrome 90+       (完整支援)
✅ Firefox 88+      (完整支援)
✅ Safari 15+       (完整支援)
⚠️ Edge 90+         (需測試 webkit 前綴)
❓ 移動瀏覽器       (Android/iOS 部分支援)
```

### 4.3 效能檢查

```javascript
// 監控全屏時的效能
const perfObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log(`${entry.name}: ${entry.duration}ms`);
  }
});

perfObserver.observe({ entryTypes: ['measure'] });

// 標記全屏切換
performance.mark('fullscreen-start');
toggleFullscreen();
performance.mark('fullscreen-end');
performance.measure('fullscreen', 'fullscreen-start', 'fullscreen-end');
```

---

## 📝 5. 代碼實施清單

### 5.1 需要修改的文件

```
src/dashboardComponent/
├── DashboardComponent.vue       (主要改動)
│   ├── + fullscreenBtn Prop
│   ├── + toggleFullscreen() 函式
│   ├── + 全屏容器包裝
│   └── + 全屏樣式規則
│
├── styles/
│   └── chartStyles.css          (或 DashboardComponent.vue <style>)
│       └── + :fullscreen 樣式規則
│
└── 無需改動
    └── components/ (圖表組件無需改動)
    └── utilities/ (工具函式無需改動)

src/views/
├── DashboardView.vue            (使用示例更新)
├── ComponentView.vue            (使用示例更新)
├── ComponentInfoView.vue        (無需改動)
└── MapView.vue                  (可選: 添加全屏支援)

src/components/dialogs/
└── MoreInfo.vue                 (MoreInfo Modal 中的全屏)
```

### 5.2 程式碼片段模板

#### **DashboardComponent.vue - 完整修改**

```vue
<!-- 在現有 script setup 中添加 -->
<script setup>
import { ref, computed, defineProps, defineEmits } from "vue";

// 新增 Props
defineProps({
  // ... 現有 props
  fullscreenBtn: {
    type: Boolean,
    default: false
  }
});

// 新增 Emits
const emits = defineEmits([
  // ... 現有 emits
  "fullscreen"
]);

// 全屏狀態
const isFullscreen = ref(false);

// 全屏切換函式
function toggleFullscreen() {
  const container = document.querySelector(
    '.dashboardcomponent-fullscreen-container'
  );
  
  if (!document.fullscreenElement) {
    container.requestFullscreen()
      .then(() => {
        isFullscreen.value = true;
        emits("fullscreen", true);
      })
      .catch((err) => {
        console.error(`全屏錯誤: ${err.message}`);
        // 備選方案: 使用 CSS 類模擬全屏
        container.classList.add('fullscreen-css-only');
        isFullscreen.value = true;
      });
  } else {
    document.exitFullscreen()
      .then(() => {
        isFullscreen.value = false;
        emits("fullscreen", false);
      });
  }
}

// 監聽全屏變化
onMounted(() => {
  document.addEventListener('fullscreenchange', () => {
    isFullscreen.value = !!document.fullscreenElement;
  });
});
</script>

<!-- 模板修改 -->
<template>
  <div
    class="dashboardcomponent-fullscreen-container"
    :class="{ 'is-fullscreen': isFullscreen }"
  >
    <div
      :class="[
        {
          dashboardcomponent: true,
          mapclosed: mode.includes('map') && !toggleOn,
          // ... 現有類
        },
      ]"
      :style="style"
    >
      <!-- Header 區保持不變，但添加按鈕 -->
      <div class="dashboardcomponent-header">
        <!-- ... 現有標題內容 -->
        
        <div
          v-if="['default', 'half', 'preview'].includes(mode)"
          class="dashboardcomponent-header-button"
        >
          <!-- 全屏按鈕 (新) -->
          <button
            v-if="fullscreenBtn"
            class="fullscreen-btn"
            @click="toggleFullscreen"
            :title="isFullscreen ? '退出全屏' : '進入全屏'"
          >
            <span>{{ isFullscreen ? 'fullscreen_exit' : 'fullscreen' }}</span>
          </button>
          
          <!-- 現有按鈕保持不變 -->
          <button v-if="addBtn" @click="$emit('add', ...)">...</button>
          <!-- ... -->
        </div>
      </div>
      
      <!-- 其他內容保持不變 -->
    </div>
  </div>
</template>

<style scoped lang="scss">
// 現有樣式保持不變

// 新增全屏相關樣式
.dashboardcomponent-fullscreen-container {
  &.is-fullscreen {
    .dashboardcomponent {
      width: 100vw !important;
      height: 100vh !important;
      max-width: 100vw !important;
      max-height: 100vh !important;
      border-radius: 0 !important;
      padding: 20px !important;
      
      .dashboardcomponent-header {
        margin-bottom: 12px;
      }
      
      .dashboardcomponent-control {
        padding: 12px 0;
      }
      
      .dashboardcomponent-chart {
        height: 85% !important;
      }
    }
  }
}

.fullscreen-btn span {
  transition: color 0.2s;
}
</style>
```

---

## 📊 6. 對標其他產品

### 6.1 參考實現

| 產品 | 全屏方式 | 特點 | 適用 |
|------|--------|------|------|
| **Grafana** | 按鈕 + 快捷鍵 | Fullscreen API | ✅ 採用 |
| **Kibana** | Modal + Zoom | 無原生全屏 | ⚠️ 參考 |
| **Tableau** | 雙擊 + 工具列 | 組件級全屏 | ✅ 建議 |
| **Google Data Studio** | 展示模式 | 類似投影儀 | 🔄 進階 |

### 6.2 最佳實踐

```
✅ 提供多種進入方式 (按鈕 + 雙擊 + 快捷鍵)
✅ ESC 快速退出
✅ 保持數據一致性
✅ 全屏時簡化 UI
✅ 支援鍵盤快捷鍵
✅ 向後兼容 (Fallback 方案)
```

---

## 🎯 7. 成功指標

### 7.1 功能指標

| 指標 | 目標 | 驗證方式 |
|------|------|---------|
| 全屏進入時間 | < 300ms | performance.measure() |
| 兼容浏覽器數 | ≥ 3 (Chrome/Firefox/Safari) | 手動測試 |
| ESC 退出成功率 | 100% | 測試矩陣 |
| 圖表交互正常 | 100% | 功能測試 |

### 7.2 用戶體驗指標

- ✅ 按鈕可視化清晰
- ✅ 反應時間快 (< 500ms)
- ✅ 無卡頓現象
- ✅ 文檔完善

---

## 📚 8. 文檔更新清單

```
需更新的文件:
├── FE-Component-Architecture-Analysis.md
│   └── + 第 4 節全屏功能說明
├── FE-Component-Cheatsheet.md
│   └── + fullscreenBtn Props
├── README.md (FE)
│   └── + 全屏功能快速開始
└── user-added/log/2026-04-XX/XXXX-fullscreen-feature.md
    └── 變更日誌
```

---

## 🚀 9. 推動計畫

### 9.1 優先級排序

| 階段 | 工作項 | 優先級 | 預期完成 |
|------|--------|--------|---------|
| Phase 1 | 基礎 Fullscreen API | P0 | Day 1 |
| Phase 2 | 雙擊 + ESC | P1 | Day 2 |
| Phase 3 | Modal 適配 | P1 | Day 2 |
| Phase 4 | 文檔與測試 | P2 | Day 3 |
| Phase 5 | 性能優化 | P2 | Day 3 |

### 9.2 風險評估

| 風險 | 等級 | 緩解措施 |
|------|------|---------|
| 瀏覽器兼容性 | 低 | Fallback CSS 類 |
| Z-index 衝突 | 低 | 明確分層策略 |
| 效能下降 | 低 | 防抖節流 |
| 現有功能破壞 | 低 | 完整回歸測試 |

---

## ✅ 10. 檢查清單

實施前：
- [ ] 代碼已備份
- [ ] 測試環境已準備
- [ ] 瀏覽器已安裝

實施中：
- [ ] Props 與 Emits 已添加
- [ ] 函式邏輯已實現
- [ ] 樣式已應用
- [ ] 本地測試已通過

實施後：
- [ ] 代碼審查已完成
- [ ] 單元測試已執行
- [ ] 集成測試已通過
- [ ] 文檔已更新
- [ ] 變更日誌已記錄

---

**文檔版本**: 1.0  
**最後更新**: 2026-04-17  
**建議者**: GitHub Copilot (PM 導向分析)
