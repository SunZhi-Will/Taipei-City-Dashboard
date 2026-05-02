# AI Studio 切頁黑屏修正（Mapbox 完整銷毀） / AI Studio Navigation Black Screen Fix (Mapbox Destroy)

## 2026-04-23 16:18

- objective:
  - 修正從 AI Studio 切換到其他頁面時出現黑屏殘留問題。

- files:
  - Taipei-City-Dashboard-FE/src/router/index.js
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - router 離開 /mapview 的清理策略由 clearEntireMap 改為 destroyMapBox。
  - AIStudioView 新增 onBeforeUnmount，頁面卸載時主動 destroyMapBox。
  - 兩層防護確保 Mapbox canvas 不會殘留在新頁面上。

- change-type:
  - Fixed

- technical-details:
  - 根因分析：
    - clearEntireMap() 僅重置 store 狀態，未呼叫 map.remove()。
    - 當 AI Studio map 模式建立過 map instance，切頁後 canvas 可能殘留，形成黑屏。
  - 修正內容：
    - router.beforeEach 中，to.path !== '/mapview' 時改呼叫 mapStore.destroyMapBox()。
    - AIStudioView 在 onBeforeUnmount 追加 mapStore.destroyMapBox() 作為防禦性清理。

- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/router/index.js
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - 結果：兩檔皆 No errors found。

- performance-impact:
  - 無顯著負面影響。
  - 切頁時多一次安全清理呼叫，避免殘留 instance 累積。

- impact-risk:
  - 低風險：僅調整切頁清理行為與 AI Studio 卸載鉤子。
  - 可能影響：若未來希望跨頁保留 map instance 需重新設計 cache 策略。

- regression-test:
  - 進入 /ai-studio，切到 map 模式，再切換至 /dashboard 或 /component，確認不再黑屏。
  - 重複切頁 3-5 次，確認畫面穩定且無 map canvas 殘留。
  - 驗證 /mapview 功能仍可正常載入與切換圖層。

- traceability:
  - N/A

- next-actions:
  - 若仍偶發黑屏，下一步檢查是否為瀏覽器快取舊 bundle 或 Docker 前端容器未熱更新。