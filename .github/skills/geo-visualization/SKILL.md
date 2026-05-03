---
name: geo-visualization
description: "Use when: 開發地理空間組件，整合 Deck.gl + Mapbox GL + GeoJSON；實作地圖互動、圖層切換、熱力圖、3D 視覺化；優化地圖效能（WebGL 加速）。適用於位置資料、空間分析、地圖儀表板。"
applyTo: "Taipei-City-Dashboard-FE/src/**"
---

# 地理空間與地圖可視化 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 資料準備 | GeoJSON 轉換、座標驗證、品質檢查 | 0 無效幾何 | P0 |
| M2: 地圖整合 | Mapbox 基礎、圖層堆疊、互動事件 | 地圖載入 <2s | P0 |
| M3: 視覺化效果 | 熱力圖、聚類、3D 建築、動畫 | WebGL 加速，FPS >30 | P1 |
| M4: 使用體驗 | 篩選、搜尋、詳情彈窗、匯出 | 首次互動 <500ms | P1 |

---

## 🔄 工作流程

### Phase 1: 資料準備與轉換
```
1. 資料來源評估
   ├─ 格式：Shapefile → GeoJSON 轉換 (ogr2ogr / mapshaper)
   ├─ 座標系統：WGS84 (EPSG:4326) vs 台灣座標 (EPSG:3826)
   ├─ 數據量：最佳化級別（簡化多邊形、分層 LOD）
   ├─ 時效性：靜態 vs 動態資料更新機制
   └─ 屬性資料：包含 name, category, metrics

2. GeoJSON 生成與優化
   ├─ 點資料 (AED、長照據點、學校)
       ├─ 格式: Feature with Point geometry
       ├─ Properties: id, name, address, coords, category
       └─ 檔案存放: public/mapData/xxx.geojson
   ├─ 線資料 (公車路線、步道)
       ├─ LineString 編碼
       └─ Properties: route_id, name, stops
   ├─ 面資料 (行政區、里別、商圈)
       ├─ Polygon/MultiPolygon 編碼
       ├─ 不超過解析度需求多邊形邊數
       └─ 座標精度 6-7 位小數
   └─ 檔案大小最佳化 (gzip, 移除冗餘欄位)

3. 資料品質檢查
   ├─ 座標驗證: bbox 在台灣範圍內
   ├─ 幾何驗證: 無自交、無孤立點
   ├─ 空值檢查: 關鍵欄位補全
   ├─ 性能測試: 載入時間 <1s
   └─ 視覺審核: 地圖上位置正確性
```

### Phase 2: Mapbox 整合
```
4. 地圖初始化
   ├─ Mapbox token 配置（API key 管理）
   ├─ 初始中心點與縮放級別 (台北市: 121.56, 25.05, zoom 11)
   ├─ 背景圖層選擇 (satellite, streets, light)
   ├─ 滑鼠操作 (pan, rotate, pitch)
   └─ 觸控操作 (pinch zoom, two-finger rotate)

5. 圖層管理
   ├─ 基礎圖層 (background, water, land, buildings)
   ├─ 資料圖層堆疊順序 (z-index)
   │   ├─ Heatmap layer (下層, 密度)
   │   ├─ Fill layer (面積, 顏色編碼)
   │   └─ Symbol layer (上層, 標題/標籤)
   ├─ 動態顯示/隱藏 (zoom 級別觸發)
   └─ 圖例與配色方案
```

### Phase 3: 整合 Deck.gl 視覺化
```
6. Deck.gl Layer 選擇與配置
   ├─ ScatterplotLayer: 點資料（AED、長照點）
   ├─ HeatmapLayer: 密度分佈
   ├─ ColumnLayer: 3D 柱狀圖（人口、設施數）
   ├─ GeoJsonLayer: 行政區邊界、特定區域
   ├─ PathLayer: 路線、交通流
   └─ PolygonLayer: 服務範圍、熱區

7. 互動事件與篩選
   ├─ 點擊事件 (onClick) → 詳情彈窗
       ├─ 顯示所有屬性資訊
       ├─ "詳細頁面"連結
       └─ 分享/標籤功能
   ├─ 懸停高亮 (onHover)
   ├─ 拖動選擇區域 (rectangular selection)
   ├─ 搜尋/篩選功能 (透過全文搜尋或類別篩選)
   ├─ 圖層動態顯示 (zoom/filter by category)
   └─ 即時更新 (WebSocket 或定期輪詢)

8. 動畫與特效
   ├─ 3D 轉場 (pitch 漸進, 縮放動畫)
   ├─ 脈衝動畫 (pulse 效果突出特定點)
   ├─ 時間軸拖曳 (時間序列資料播放)
   └─ 圖層漸現 (opacity transition)
```

### Phase 4: 效能最佳化與測試
```
9. 效能優化
   ├─ WebGL 加速確認
   ├─ 圖層聚合 (clustering 大數據集)
   ├─ 層級細節 (LOD): zoom <10 顯示聚合，zoom >12 單點
   ├─ 虛擬滾動 (info panel)
   ├─ 圖像快取策略
   └─ 行動設備測試 (降低特效複雜度)

10. 測試與驗證
    ├─ 功能測試: 所有互動事件、篩選、搜尋
    ├─ 效能測試: 與 Chrome DevTools 計時
    ├─ 無障礙測試: 鍵盤導航、螢幕閱讀器
    ├─ 跨瀏覽器測試 (Chrome, Firefox, Safari)
    └─ 行動測試 (iOS Safari, Chrome Android)
```

---

## 💡 技術決策點

### 🗺️ 座標系統與轉換
| 系統 | EPSG | 用途 | 轉換工具 |
|------|------|------|--------|
| WGS84 | 4326 | Web 標準，Mapbox 使用 | - |
| 台灣座標 | 3826 | 台灣政府資料集 | proj4js, turf |
| 台灣 TM2 | 3825 | 舊系統 | 同上 |

```javascript
// 座標轉換範例
import proj4 from 'proj4';

const EPSG3826 = "+proj=tmerc +lat_0=0 +lon_0=121 +k=0.9999 +x_0=250000 +y_0=0";
const EPSG4326 = "+proj=longlat +datum=WGS84";

const [lon, lat] = proj4(EPSG3826, EPSG4326, [x, y]);
```

### 🎨 顏色編碼與配色
| 資料類型 | 配色模式 | 例子 |
|---------|--------|------|
| 定序 (順序) | Sequential | 綠 → 紅 (低 → 高) |
| 定名 (類別) | Categorical | 5+ 不同顏色 |
| 背離 (中點) | Diverging | 藍 ← 白 → 紅 |

```json
{
  "health_facilities": {
    "aed": "#E74C3C",
    "clinic": "#3498DB",
    "hospital": "#8E44AD"
  }
}
```

### 🎯 Deck.gl vs Mapbox 選擇
| 場景 | 選擇 | 理由 |
|------|------|------|
| 行政邊界、道路標籤 | Mapbox | 原生支援，效能優 |
| 萬筆點位、3D | Deck.gl | WebGL 加速，流暢 |
| 混合方案 | 兩者套疊 | Mapbox 基礎 + Deck.gl overlay |

### 🔄 GeoJSON 大檔案處理
```javascript
// 懶加載策略
async function loadGeoJSONTiled(bbox) {
  // 僅載入視區內瓷磚
  const tiles = getTilesInBBox(bbox);
  return Promise.all(tiles.map(t => fetch(`/mapData/${t}.geojson`)));
}
```

---

## 🛡️ 實踐檢查清單

- [ ] 所有 GeoJSON 已用 geojsonhint 驗證無效幾何
- [ ] 座標系統文件化（座標來源、精度、更新頻率）
- [ ] Mapbox token 已存環境變數（不硬編碼）
- [ ] 圖層 z-index 與 filter 表達式已最佳化
- [ ] 聚合邏輯已配置（>100 點自動聚合）
- [ ] 彈窗不會超出視口（邊界檢查）
- [ ] 地圖載入時間 <2s（Chrome throttled）
- [ ] 移動設備測試（單指拖曳、雙指縮放）
- [ ] 鍵盤快捷鍵支援（上下左右、+/- 縮放）
- [ ] 無標籤點均可透過懸停顯示資訊
- [ ] 搜尋結果反白/高亮
- [ ] 列印/匯出地圖功能已測試
- [ ] 暗模式背景圖層已適配

---

## 📚 參考檔案

- **GeoJSON 資料**: [public/mapData/](../Taipei-City-Dashboard-FE/public/mapData/)
- **地圖組件**: [src/components/](../Taipei-City-Dashboard-FE/src/components/) (搜尋 "map")
- **Mapbox 官方**: https://docs.mapbox.com/mapbox-gl-js/
- **Deck.gl 文檔**: https://deck.gl/docs
- **GeoJSON 指南**: https://tools.ietf.org/html/rfc7946
- **轉換工具**: ogr2ogr, mapshaper.org
