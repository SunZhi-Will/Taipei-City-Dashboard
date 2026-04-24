# AI Studio 降低重載與切換延遲 / Reduce Reload Overhead in AI Studio Mode Switching and Carousel

## 2026-04-24 11:42

- objective:
  - 避免 AI Studio 在「地圖 / 圖表 / 輪播」切換時每次重載，減少等待時間。
  - 降低輪播切頁時圖表被重建導致的載入延遲。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - 將 AI Studio 右側主要模式區塊由 `v-if / v-else-if` 改為 `v-show`，保持元件掛載，避免每次切換模式都重新建立與資料重載。
  - 移除輪播投影片內容區的動態 `key` 重建機制，避免每次切頁都強制卸載/重掛圖表元件。

- change-type:
  - Fixed
  - Changed

- technical-details:
  - `AIStudioView.vue`：
    - presentation/components/map/web 區塊改為 `v-show`，讓非目前顯示模式只隱藏不銷毀。
    - 保留原本空狀態與資料判斷邏輯，不改 API 與 store 結構。
  - `AIStudioPresentationCanvas.vue`：
    - 移除 `slide-content` 的 `:key="content-${slideAnimKeys[index]...}"`。
    - 保留輪播進度/切頁邏輯，僅取消會造成 DOM 重建與圖表重新載入的觸發點。

- verification:
  - `get_errors`：
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue -> No errors found
    - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue -> No errors found
  - 邏輯檢查：
    - 模式切換改為顯示控制，不再觸發整塊元件生命週期重建。
    - 輪播切頁不再因 key 變化而重建內容節點。

- performance-impact:
  - 預期明顯降低模式切換與輪播切頁的重載時間。
  - 初始記憶體佔用可能略增（因元件維持掛載），但可換取切換時延遲大幅下降。

- impact-risk:
  - 中低風險：`v-show` 會保留背景元件運作；若某些元件內有持續輪詢，可能在隱藏時仍持續執行。
  - 目前主要目標為降低重載體感，符合本次需求；若後續需進一步控資源，可再針對隱藏狀態做節流。

- regression-test:
  - 在 AI Studio 來回切換「圖表牆 / 地圖 / 輪播」，觀察是否不再出現完整重載等待。
  - 在輪播自動播放時，確認切換頁面不再頻繁重新初始化圖表。
  - 驗證全螢幕沉浸模式下的模式切換仍正常。

- traceability:
  - N/A

- next-actions:
  - P1: 若仍感覺地圖慢，可再補「隱藏狀態停止非必要更新」策略（例如隱藏時暫停圖層動態刷新）。
  - P2: 可加入簡單切換耗時指標（before/after）量化優化成效。
