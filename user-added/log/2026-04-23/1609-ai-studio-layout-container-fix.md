# AI Studio 版型容器修正 / AI Studio Layout Container Fix

## 2026-04-23 16:09

- objective:
  - 修正 AI Studio 切換進入時版型異常、容器高度與外層 layout 假設不一致的問題。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 在 App.vue 為 ai-studio 新增專屬 layout 分支，不再落到 plain router-view。
  - 讓 AIStudioView 改為填滿父層容器高度，而不是自行扣除 60px navbar 高度。
  - 避免 AI Studio 在切頁後出現高度錯誤、滾動區混亂或畫面看起來「怪怪的」問題。

- change-type:
  - Fixed

- technical-details:
  - 問題根因：
    - App.vue 對 mapview/dashboard/admin/component 都有專屬 layout 分支，但 ai-studio 沒有。
    - AIStudioView 內部使用整頁 flex 版型，且根元素高度寫死為 calc(var(--vh) * 100 - 60px)。
    - 當它被掛在 App 最末端 plain router-view 分支時，外層缺少和其他主頁一致的高度/overflow 容器，造成 layout 行為不穩定。
  - 修正方式：
    - App.vue 新增 authStore.currentPath === 'ai-studio' 分支，使用 app-content > app-content-main > app-content-body--flush 包裝 RouterView。
    - AIStudioView 將 .aistudio 高度由 calc(var(--vh) * 100 - 60px) 改為 width: 100%; height: 100%。
    - 新增 app-content-body--flush，讓 AI Studio 這個整頁畫布不受既有底部 padding 影響。

- verification:
  - 使用 VS Code diagnostics 檢查：
    - Taipei-City-Dashboard-FE/src/App.vue
    - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - 結果：兩個檔案皆 No errors found。
  - 程式碼檢查：
    - 確認 App.vue 已新增 ai-studio layout 分支。
    - 確認 AIStudioView 根容器已改為依附父層 100% 高度。

- performance-impact:
  - 無顯著效能影響。
  - 僅調整外層容器與高度配置，無新增昂貴運算。

- impact-risk:
  - 低風險：影響範圍限定在 AI Studio route 的版型包裝。
  - 若後續 AI Studio 想改成完全 standalone 頁，可再獨立調整 NavBar 顯示策略。

- regression-test:
  - 從 dashboard 切到 /ai-studio，確認左右分欄正常、無多餘殘留 layout。
  - 驗證 AI Studio 左欄收合、右側 components/map/web 畫布高度正常。
  - 驗證返回其他頁面後，不出現容器高度殘留或滾動異常。

- traceability:
  - N/A

- next-actions:
  - 建議直接切換 dashboard -> ai-studio -> dashboard 實測一次，確認版型切換已穩定。