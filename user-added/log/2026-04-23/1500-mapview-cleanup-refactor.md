# 地圖頁面卸載問題修復 & 程式重構 / MapView Page Cleanup & Code Refactoring

## 2026-04-23 15:00

### objective:
- 解決進入地圖頁面後，切換到其他頁面時內容區仍顯示地圖的問題
- 重構 MapView.vue，拆分複雜邏輯，提升程式可維護性

### files:
- `Taipei-City-Dashboard-FE/src/store/mapStore.js` - 改進 destroyMapBox() 方法
- `Taipei-City-Dashboard-FE/src/components/map/MapContainer.vue` - 新增 onBeforeUnmount 鉤子
- `Taipei-City-Dashboard-FE/src/views/MapView.vue` - 簡化並重構，新增卸載邏輯
- `Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebar.vue` - 新建，提取側邊欄邏輯

### summary:
1. **mapStore.js 改進 destroyMapBox()**
   - 移除所有事件監聽器 (load, click, dblclick, idle, moveend, zoomend, dragend)
   - 改進異常處理，使用 try-catch 防止卸載時的錯誤
   - 確保 marker、overlay 完全清理
   - 重置所有 state (包含 viewPoints, prevMrtCars, layerUpdateTime)

2. **MapContainer.vue 新增卸載鉤子**
   - 導入 `onBeforeUnmount` 生命週期鉤子
   - 在卸載時明確呼叫 `mapStore.destroyMapBox()`

3. **MapView.vue 重構**
   - 移除所有複雜的側邊欄邏輯
   - 新增 `onBeforeUnmount` 鉤子，確保路由離開時清理
   - 簡化組件，專注路由和導航邏輯

4. **MapLayerSidebar.vue 新建**
   - 提取所有圖層控制邏輯（儀表板選擇、組件切換、圖層勾選）
   - 自成一個獨立、可複用的組件
   - 包含所有相關的 utility 函數和樣式

### change-type:
- Fixed (解決地圖停留問題)
- Changed (重構架構)
- Added (新增 MapLayerSidebar 組件)

### technical-details:
**根本原因：**
- Mapbox GL JS 實例需要明確呼叫 `.remove()` 才能完全卸載
- 未移除的事件監聽器會導致 Mapbox 實例在記憶體中繼續運行
- Mapbox Canvas 會蓋住新頁面的內容

**修復流程：**
1. 在 mapStore.destroyMapBox() 中移除所有事件監聽器
2. 確保 marker、overlay、popup 都被清理
3. 呼叫 `map.remove()` 完全銷毀實例
4. 在 MapContainer.vue 和 MapView.vue 中都新增卸載邏輯，雙保險

**程式拆分優勢：**
- MapView.vue 由原來 600+ 行簡化至 100+ 行
- MapLayerSidebar 獨立管理層級控制邏輯
- 責任分離，更易於維護和測試
- 減少 MapView 中的認知負荷

### verification:
```bash
# 1. 檢查編譯是否成功
npm run build

# 2. 手動測試流程：
# - 進入儀表板
# - 點擊進入地圖頁面
# - 在側邊欄選擇不同儀表板/組件
# - 返回儀表板首頁
# - 驗證首頁內容正常顯示（不被地圖蓋住）

# 3. 瀏覽器開發工具檢查：
# - 開啟 DevTools -> Elements 
# - 確認切換頁面時 #mapboxBox 的 canvas 被移除
# - 檢查 Memory 標籤確認 Mapbox 實例被回收
```

### performance-impact:
- 改善：減少記憶體洩漏風險，長時間使用後應用穩定性提升
- 預期改進：頻繁切換頁面時不會累積已銷毀的 Mapbox 實例

### impact-risk:
- **邊界情況**：如果用戶在地圖載入完成前快速離開頁面
  - 緩解：destroyMapBox() 的 try-catch 會處理這種情況
- **回退策略**：如遇問題，可恢復至 MapView.vue.bak 並重新測試

### regression-test:
- [ ] 地圖頁面正常載入
- [ ] 圖層控制側邊欄功能正常（新增/移除/勾選圖層）
- [ ] 切換儀表板不會有殘留地圖
- [ ] 多次進出地圖頁面後無記憶體洩漏
- [ ] 行動裝置上側邊欄收縮/展開正常

### traceability:
- 相關討論：用戶報告「進入地圖頁面再去其他頁面，內容區始終是地圖」
- 修復方案：Promise 式的完整卸載機制

### next-actions:
- [ ] 實機測試各品牌行動裝置
- [ ] 監控生產環境是否有相關錯誤日誌
- [ ] 考慮建立 Mapbox 實例的單例模式（未來優化）
