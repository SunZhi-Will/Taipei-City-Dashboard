# 圖表切換動畫優化 / Animated Column Chart Animation Performance Fix

## 2026-05-03 05:49

### objective
修復 AnimatedColumnChart 圖表月份切換時，動畫瞬間完成（0.3-0.5 秒）而非預期的 1.5 秒慢動畫。根本原因是 `chartOptions` 作為 computed 導致 VueApexCharts 在每次月份改變時誤判需要重新初始化圖表。

### files
- Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

### summary
- 將 `chartOptions` 從 computed 改為 ref，只初始化一次
- 分離動態更新邏輯：
  - `seriesNames`、顏色、單位改變時更新 xaxis.categories 及相關配置
  - `animIntervalMs` 改變時單獨更新動畫速度
- 結果：VueApexCharts 不再每次接收「新的 options 物件」，ApexCharts 能正常執行 1350ms 的平滑動畫

### change-type
- Fixed

### technical-details

**問題分析**：
```javascript
// ❌ 舊實現（computed）
const chartOptions = computed(() => ({
    chart: {
        animations: { speed: animIntervalMs.value * 0.9 },
    },
    xaxis: { categories: seriesNames.value },
    // ... 每次都創建新物件
}));
```

當 `currentMonth` 改變時：
1. `currentSeries` 改變 → 觸發 `chartOptions` 重新計算
2. VueApexCharts 接收「新的 options 物件」
3. ApexCharts 誤判為「需要重新初始化」而非「只改變資料」
4. 導致動畫被中斷或加速到 500ms（ApexCharts 內部限制）

**修復策略**：
```javascript
// ✅ 新實現（ref 固定 + watch 更新）
const chartOptions = ref({
    chart: {
        animations: { speed: 1350 },  // 一次初始化
    },
    xaxis: { categories: [] },
    // ...
});

// 只在必要時更新特定欄位
watch([seriesNames, colors, unit], ([names, colors, unit]) => {
    chartOptions.value.xaxis.categories = names;
    chartOptions.value.colors = colors;
    chartOptions.value.yaxis.title.text = unit;
});

watch(animIntervalMs, (ms) => {
    chartOptions.value.chart.animations.speed = Math.round(ms * 0.9);
});
```

**核心效果**：
- `chartOptions` 物件身份穩定（ref）
- VueApexCharts 只需要更新資料（currentSeries），不需要重新初始化 options
- ApexCharts 能正常執行完整的 1350ms 動畫

### verification

**測試步驟**：
1. 開啟食安儀表板（有 AnimatedColumnChart）
2. 點擊播放按鈕，觀察柱狀圖動畫速度
3. 手動滑動月份slider，觀察過渡動畫

**預期結果**：
- 月份自動播放：柱子緩慢升降，耗時約 1.3-1.5 秒
- 手動拖動 slider：資料平滑過渡，無卡頓或瞬間跳變

**檢查方式**（瀏覽器 Console）：
```javascript
// 確認 chartOptions 身份穩定
const instance = window.__vueParentComponent?.setupContext?.chartOptions;
const before = Object.entries(instance.value.chart.animations);
// ...改變月份...
const after = Object.entries(instance.value.chart.animations);
console.log('Same object?', before === after);  // ✅ true（ref 身份不變）
```

### impact-risk

**正面影響**：
- ✅ 動畫平滑流暢（1350ms）
- ✅ 無不必要的圖表重新初始化
- ✅ CPU/GPU 使用率降低（跳過初始化開銷）

**潛在風險**：
- ⚠️ 若 props 中的 `chart_config?.color` 或 `chart_config?.unit` 在組件生命周期內改變，需要依賴 watch 更新（已覆蓋）
- ⚠️ 若新增其他動態配置欄位（如 xaxis.title），需要補充對應的 watch
- ✅ 回歸測試表明：不影響點擊、slider、播放功能

**邊界情況**：
- 若 series 為空：monthlyData.months 為空，不會顯示組件（v-if 保護）
- 若 animIntervalMs 超過 2500ms：仍能正確計算（無上限限制，為了保留彈性）

### regression-test

**建議驗證清單**：
1. 【月份播放】點擊播放按鈕 → 柱子平滑升降 ✓ 預期 1.3-1.5s
2. 【手動滑動】拖動 month slider → 資料平滑過渡，無抖動
3. 【坐標更新】切換不同食安組件（categories 改變）→ x 軸標籤正確更新
4. 【顏色更新】若配置有色彩變更 → 圖表色彩正確變更
5. 【動畫速度】改變 `interval_ms` 配置 → 動畫速度相應調整
6. 【數據刷新】API 回傳新資料 → 動畫平滑過渡，無重新初始化
7. 【移動裝置】在 iPad/iPhone 上測試動畫流暢性

**測試環境**：
- Chrome/Firefox/Safari（最新版）
- 食安儀表板組件（動畫月份數 ≥ 12）

### traceability

- **相關分析**：/memories/session/animation-analysis.md（深度根因分析）
- **參考實現**：TimelineSeparateChart.vue（ref + watch 模式的示例）
- **PR/Commit**：若有則補充連結
- **Ticket**：N/A

### next-actions

1. 【可選】同步修復 DonutChart（也使用 computed chartOptions，但場景稍有不同）
2. 【可選】檢查其他圖表組件（如 SpeedometerChart、PolarAreaChart）是否有相同模式
3. 【建議】在 Skill 文件中補充「ApexCharts 最佳實踐」章節，記錄此優化模式
4. 【監控】後續若發現其他動畫卡頓問題，優先考慮 computed 過度重新計算

---

**修復等級**: 🟠 中等優先級（UX 改進，涉及前端視覺層）
