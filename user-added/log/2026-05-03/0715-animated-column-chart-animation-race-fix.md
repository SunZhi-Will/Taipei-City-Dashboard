# 修復柱狀圖動畫「起步緩慢瞬間完成」問題 / Fix AnimatedColumnChart easing + animateGradually race condition

## 2026-05-03 07:15

- objective:
  - 修正 AnimatedColumnChart 播放時，動畫一開始極緩慢、後面瞬間完成的視覺異常

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/AnimatedColumnChart.vue

- summary:
  - 問題根因為三個複合因素：
    1. `easeinout` 貝茲曲線前 25% 時間只移動 5% 距離，造成「起步極慢」的感知
    2. `animateGradually.delay = 80ms × N根柱子` 使總動畫時間超出 `setInterval` 的 1500ms 窗口：
       - 3 根柱子：1510ms > 1500ms（超出 10ms）
       - 6 根柱子：1750ms > 1500ms（超出 250ms）
    3. `setInterval` 在動畫尚未結束時觸發 `updateSeries()`，ApexCharts 強制 snap 所有未完成動畫至最終值（< 1 frame = ~16ms），即「瞬間完成」
  - 修正：
    - 停用 `animateGradually`（設計給初始渲染，非動態更新）
    - easing 改為 `easeout`（起步即有可見速度，視覺更線性流暢）
    - speed 比例從 `0.9 × interval` 降為 `0.6 × interval`（1500ms → 900ms），確保動畫在下一個 interval 前留有 600ms 緩衝

- change-type:
  - Fixed

- technical-details:
  - animateGradually 在 ApexCharts v3.x 同時影響 initial 與 dynamic animation，並非僅首次渲染
  - setInterval 執行在 event loop，ApexCharts 動畫執行在 requestAnimationFrame，兩者不同步
  - easeinout cubic bezier 進度公式：t=25% 時 progress≈5%；t=50% 時 progress≈50%
  - 舊 speed 0.9 ratio：動畫 1350ms，last bar 完成時間 1350+160=1510ms，超出 1500ms
  - 新 speed 0.6 ratio：動畫 900ms，所有 bar 同步完成於 900ms，距 1500ms 有 600ms 安全緩衝
  - easeout 曲線從全速開始並線性減速，視覺上柱子立即彈起、自然降落到目標高度

- verification:
  - 肉眼驗證：播放動畫，各月份柱子應快速彈起（900ms 內）後靜止，無「緩慢起步瞬間完成」現象
  - 計算驗證：900ms < 1500ms，600ms 緩衝即使 JS event loop 延遲 200ms 仍安全
  - 邊界驗證：`animIntervalMs` 最小值 900ms（Math.max(900, ...)），此時 speed=540ms，仍低於 interval

- performance-impact:
  - 動畫縮短 450ms（1350ms→900ms），每個 interval 剩餘 600ms 靜止，CPU/GPU 動畫負擔降低約 33%
  - 停用 animateGradually 消除了 N 個 RAF callback 的 stagger 計算

- impact-risk:
  - 影響範圍：僅 AnimatedColumnChart 組件（食安月份柱狀圖動畫）
  - easing 從 easeinout 改為 easeout：動畫感觀更活潑（快速起跳，緩慢落定），符合「月份切換」的互動語意
  - 若 interval_ms 配置值更動（例如改為 2000ms），speed 自動跟隨為 1200ms，邏輯自洽

- regression-test:
  - [ ] 開啟食安儀表板，播放月份動畫，確認柱子流暢完整動畫（900ms 內結束）
  - [ ] 滑動 slider 手動切換月份，確認動畫正確執行
  - [ ] 開啟多個月份時間範圍，確認首次 mount 時初始動畫也正常
  - [ ] 瀏覽器分頁切換後回來，確認動畫不會在同幀完成多個月份

- traceability:
  - N/A（口頭回報視覺異常，無 ticket）

- next-actions:
  - 若 DonutChart.vue 也有類似 animateGradually 問題，可參照此修法（目前 DonutChart speed ratio 為 0.8，相對安全）
