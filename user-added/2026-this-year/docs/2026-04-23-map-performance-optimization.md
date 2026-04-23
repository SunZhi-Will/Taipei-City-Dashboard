# 地圖效能全面優化實作報告 / Full Map Performance Optimization Report

## 日期
- 2026-04-23

## 背景問題
- 使用者反映地圖在載入、切換圖層、與 3D 捷運顯示時有明顯卡頓。
- 經程式碼檢視後，瓶頸集中在：
  - 重複載入大型 GeoJSON。
  - WFS 請求抓取筆數過大。
  - Isoline 生成計算量過高。
  - 3D layer 持續重繪與每幀高成本渲染。

## 實作目標
1. 降低主執行緒（Main Thread）負擔。
2. 降低網路與 JSON parse 開銷。
3. 控制 3D 渲染頻率，避免無效重繪。
4. 保持既有功能可用，不改變對外操作流程。

## 已實作優化項目

### 1) 基礎圖層重複載入消除
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 將 metrotaipei town/village 的 label source 作為 fallback 邊界圖層資料來源。
  - 移除原本 fallback 情境下再建立第二份同資料 source 的流程。
- 效益：
  - 避免同一份大檔重複下載/解析/佔記憶體。
  - 初次進圖載入峰值下降，GC 壓力降低。

### 2) 本地 GeoJSON 加入快取
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 新增 localGeoJsonCache。
  - fetchLocalGeoJson 先查快取，命中就直接加圖層，不再重抓。
- 效益：
  - 減少重複 HTTP 請求與重複 JSON parse。
  - 多次切換同圖層時體感顯著改善。

### 3) WFS 請求加上 feature cap 與視窗 bbox
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 新增 buildWfsUrl()，統一組 URL。
  - 將 maxFeatures 從極大值改為受控上限（wfsFeatureCap，預設 20000，且有安全上下限）。
  - 依當前地圖視窗附加 bbox 篩選。
- 效益：
  - 降低後端傳輸量與前端解析量。
  - 在視窗導向場景中，資料更貼近使用者當前關注區域。

### 4) source 錯誤監聽去重
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 新增 mapSourceErrorHandlers 與 attachSourceErrorHandler()。
  - 每個 source 只綁定一次 error handler。
  - destroyMapBox 時統一解除。
- 效益：
  - 避免長時間使用時 listener 累積。
  - 降低事件分發與記憶體風險。

### 5) Isoline 計算量控制
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 新增 getAdaptiveIsolineGridSize()，依 zoom 自適應網格粒度。
  - 新增 maxIsolineInterpolationPoints，超量時自動放寬 gridSize。
  - 新增 maxIsolineSegments，限制輸出等值線段總量。
- 效益：
  - 避免 isoline 在主執行緒造成長時間卡住。
  - 兼顧視覺品質與計算成本。

### 6) 3D 捷運渲染路徑優化
- 檔案：Taipei-City-Dashboard-FE/src/store/mapStore.js
- 做法：
  - 由「每台車迴圈內 render(scene,camera)」改為「每幀只 render 一次」。
  - 每台車改為更新自身 model matrix（matrixAutoUpdate=false），由單次場景渲染輸出。
  - triggerRepaint 改為條件觸發：僅動畫中或 tooltip 跟隨時持續重繪。
- 效益：
  - 顯著降低 GPU/CPU 無效工作。
  - 提升縮放/拖曳流暢度與穩定 FPS。

## 新增可調參數
- wfsFeatureCap: 20000
- maxIsolineInterpolationPoints: 120000
- maxIsolineSegments: 30000

## 風險與注意事項
1. WFS cap 可能在某些分析場景造成資料被截斷：
- 建議後續加入 UI 提示（例如「目前顯示為視窗內前 N 筆」）。

2. Isoline 降採樣可能讓細節略為平滑：
- 建議提供進階模式切換（效能優先 / 精度優先）。

3. 3D 渲染改為矩陣驅動後，若模型資產規格變更：
- 需重新校正模型 scale 與 offset。

## 驗證建議（下一步）
1. 在同一台裝置量測優化前後：
- 首次地圖可互動時間（TTI）
- 拖曳時平均 FPS
- 切換圖層延遲

2. 大圖層壓測：
- 連續切換 20 次圖層
- 觀察記憶體曲線與 listener 數量

3. 3D 場景驗證：
- 不同 zoom 下 2D/3D 切換是否連續
- tooltip 跟隨是否平滑

## 結論
- 本次屬於「熱點直修 + 結構止血」：先把最重的重複工作與無效重繪移除。
- 在不改動使用者操作流程前提下，已完成可感知的性能優化主線。
- 若要再上台階，建議下一階段導入：
  - Worker 化 isoline/voronoi
  - 向量瓦片化（tile-based）
  - 效能儀表板（FPS、memory、layer load time）
