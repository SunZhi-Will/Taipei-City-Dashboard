# 地圖效能全面優化實作 / Full Map Performance Optimization Implementation

## 2026-04-23 16:22

- objective:
  - 修復地圖頁面卡頓，集中處理重複資料載入、過量資料抓取、過重計算與 3D 重繪成本。

- files:
  - Taipei-City-Dashboard-FE/src/store/mapStore.js
  - user-added/2026-this-year/docs/2026-04-23-map-performance-optimization.md

- summary:
  - 在 mapStore 中落地多項性能優化：base layer 載入去重、GeoJSON 快取、WFS 請求上限與 bbox、isoline 自適應降載、3D 單幀單次渲染與條件 repaint。
  - 新增詳細技術文件，完整記錄優化背景、方法、參數、風險與後續驗證建議。

- change-type:
  - Changed

- technical-details:
  - 新增 state 參數：localGeoJsonCache、mapSourceErrorHandlers、wfsFeatureCap、maxIsolineInterpolationPoints、maxIsolineSegments。
  - initializeBasicLayers fallback 流程改為重用 label source，移除重複 source 建立。
  - fetchLocalGeoJson 先查 cache，命中時直接 addGeojsonSource。
  - 新增 buildWfsUrl/getCurrentBboxParam，將 WFS 請求改為 capped + bbox。
  - 新增 attachSourceErrorHandler，避免同 source 重複 error listener。
  - Isoline 改為 zoom 自適應 gridSize，並在點數/線段超限時自動降載。
  - 3D render 改為每幀一次 renderer.render，模型改以 matrix 更新，triggerRepaint 改為條件觸發。
  - destroyMapBox 增加 error handler 解除與 cache reset，避免長時間使用累積風險。

- verification:
  - 問題檢查：對 Taipei-City-Dashboard-FE/src/store/mapStore.js 執行語法/診斷檢查，結果為 No errors found。
  - 參考命令/依據：get_errors 工具檢查指定檔案。

- performance-impact:
  - 降低主執行緒阻塞：isoline 與重複 JSON parse 壓力下降。
  - 降低渲染負載：3D 場景從多次 render 降為單次 render。
  - 降低網路與反序列化成本：WFS cap + bbox 限縮資料量。

- impact-risk:
  - WFS cap 可能導致極端情況下資料截斷，需要後續 UI/提示補強。
  - isoline 降採樣會影響局部精細度，需評估是否提供高精度模式。

- regression-test:
  - 驗證地圖首次進入與切換圖層是否正常顯示。
  - 驗證 3D 捷運圖層在不同 zoom 下 2D/3D 切換與 tooltip 顯示。
  - 驗證 repeated toggle（連續開關多圖層）不應出現持續惡化卡頓。

- traceability:
  - Related docs: user-added/2026-this-year/docs/2026-04-23-map-performance-optimization.md

- next-actions:
  - P1: 將 voronoi/isoline 移至 Web Worker。
  - P1: 建立性能基準（TTI/FPS/Layer load time）並納入回歸檢核。
