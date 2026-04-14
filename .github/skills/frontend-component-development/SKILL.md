---
name: frontend-component-development
description: "Use when: 使用 Vue 3 開發儀表板組件、新增圖表（ApexCharts/Three.js）、實作地圖交互（Deck.gl）、狀態管理（Pinia）、路由與快取。適用於新 Widget、資料視覺化、UI/UX 改進。"
applyTo: "Taipei-City-Dashboard-FE/src/**"
---

# 前端組件開發 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 組件設計 | 原型、互動規格、無障礙檢查 | 設計評審通過 | P0 |
| M2: 實現核心邏輯 | Vue 3 Composition API、狀態管理 | 100% 單元測試 | P0 |
| M3: 資料視覺化 | 圖表、地圖、動畫整合 | <100ms 首屏渲染 | P1 |
| M4: 效能與 SEO | 代碼分割、快取策略、metadata | Lighthouse score >90 | P1 |

---

## 🔄 工作流程

### Phase 1: 需求與設計
```
1. 確定組件類型
   ├─ 資訊卡片（KPI、統計）
   ├─ 時間序列圖、分佈圖、地圖
   ├─ 表格、篩選器、互動元素
   └─ 即時更新 vs 定期更新

2. 資料流設計
   ├─ API endpoint 確認
   ├─ State schema 設計（Pinia store）
   ├─ 緩存策略（client-side 或 server-side）
   └─ 實時更新方案（polling vs WebSocket）

3. UI/UX 設計
   ├─ 線框圖、互動原型
   ├─ 無障礙需求 (WCAG 2.1 AA)
   ├─ 響應式設計 (mobile/tablet/desktop)
   └─ 暗模式支援
```

### Phase 2: 建立 Vue 組件結構
```
4. 新增組件 (src/components/)
   ├─ 組件分類目錄 (DataDisplay/, Input/, Layout/)
   ├─ 使用 Vue 3 Composition API (不用 Options API)
   ├─ Props validation + TypeScript (if available)
   └─ 實現 computed, watch, onMounted hooks

5. 實現互動邏輯
   ├─ 事件發射 (emit) 至父組件或 store
   ├─ 表單驗證、輸入清理
   ├─ 載入、錯誤、空狀態處理
   └─ Loading skeleton 或 progress bar
```

### Phase 3: 整合狀態管理與資料
```
6. 設定 Pinia Store (src/store/)
   ├─ State: 資料快照
   ├─ Getters: derived state, filtering
   ├─ Actions: 非同步資料取得
   └─ Error 與 loading 子狀態

7. 資料取得與快取
   ├─ API 調用 (async/await 或 suspense)
   ├─ 實装 client-side 快取（時間戳驗證）
   ├─ 重試機制與退避演算法
   └─ 即時更新（定期輪詢或 WebSocket）
```

### Phase 4: 視覺化與效能
```
8. 整合圖表庫
   ├─ ApexCharts: 時間序列、柱狀圖、堆疊圖
   ├─ Three.js: 3D 動畫、複雜視覺化
   ├─ Deck.gl + Mapbox: 地理空間動畫
   └─ 圖表更新策略（完整重繪 vs 增量更新）

9. 效能優化
   ├─ 代碼分割 (dynamic import)
   ├─ 圖片最佳化 (WebP, 懶加載)
   ├─ 虛擬捲軸 (大數據表格)
   ├─ Debounce/throttle 互動事件
   └─ 效能檢測 (Performance API)

10. 測試與遠程檢驗
    ├─ 單元測試 (Vue Test Utils)
    ├─ 隱喻測試 (E2E Cypress/Playwright)
    ├─ 無障礙測試 (axe-core)
    └─ Lighthouse 審計
```

---

## 💡 技術決策點

### 🎨 圖表選擇矩陣
| 資料類型 | 推薦庫 | 特性 |
|---------|-------|------|
| 時間序列（多條線） | ApexCharts | 互動縮放、即時更新 |
| 大規模散點圖 | Deck.gl | WebGL 加速、百萬筆點 |
| 3D 可視化 | Three.js | 自定義幾何、動畫 |
| 商務圖表 | ApexCharts | 開箱即用，響應式 |

### 🔄 狀態管理模式
```javascript
// Pinia Store 結構範例
export const useResourceStore = defineStore('resource', {
  state: () => ({
    items: [],
    loading: false,
    error: null,
    lastFetched: null, // 快取時戳
  }),
  getters: {
    isCacheValid: (state) => {
      return state.lastFetched && Date.now() - state.lastFetched < 5*60*1000
    },
  },
  actions: {
    async fetchItems() {
      if (this.isCacheValid) return; // 跳過重複取得
      this.loading = true;
      try {
        this.items = await api.getItems();
        this.lastFetched = Date.now();
      } catch (e) {
        this.error = e;
      } finally {
        this.loading = false;
      }
    },
  },
})
```

### 📱 響應式設計斷點
```css
/* Tailwind + 自定義 */
- sm: 640px (tablet)
- md: 1024px (desktop)
- lg: 1280px (wide)
```

### ⚡ 效能預算
| 指標 | 目標 | 監控工具 |
|------|------|--------|
| First Contentful Paint | <1.5s | Lighthouse |
| Largest Contentful Paint | <2.5s | Web Vitals |
| Cumulative Layout Shift | <0.1 | PageSpeed |
| Time to Interactive | <3.5s | Chrome DevTools |

---

## 🛡️ 實踐檢查清單

- [ ] 組件 props/emits 文件化（JSDoc 或 Storybook）
- [ ] 支援完整無障礙特性 (aria-*, role, keyboard nav)
- [ ] 響應式移動設計測試（Chrome DevTools 模擬）
- [ ] 手機低網速測試（Chrome DevTools throttling）
- [ ] 即時資料更新邏輯已測試（模擬 WebSocket）
- [ ] 圖表大數據載入測試（>10k 筆資料）
- [ ] 狀態持久化（localStorage/SessionStorage）
- [ ] 錯誤狀態和重試流程UI已設計
- [ ] 暗模式 CSS 變數已檢驗
- [ ] Lighthouse 各項 >85 分
- [ ] 組件回歸測試快照已建立

---

## 📚 參考檔案

- **組件目錄**: [src/components/](../Taipei-City-Dashboard-FE/src/components/)
- **儀表板組件**: [src/dashboardComponent/](../Taipei-City-Dashboard-FE/src/dashboardComponent/)
- **Pinia Store**: [src/store/](../Taipei-City-Dashboard-FE/src/store/)
- **路由配置**: [src/router/](../Taipei-City-Dashboard-FE/src/router/)
- **Vite 配置**: [vite.config.js](../Taipei-City-Dashboard-FE/vite.config.js)
- **Tailwind 設定**: 檢查 src/assets/ 中的 CSS
