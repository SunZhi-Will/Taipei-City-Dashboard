# 食安儀表板專屬版型優化 / Food Safety Dashboard Layout Profile Tuning

## 2026-05-03 03:20

- objective:
  - 修正食安儀表板套用泛用自動跨度規則後產生的視覺失衡問題。
  - 讓 food_safety_tpe / food_safety_taipei 具備更穩定、具設計感的專屬版型節奏。

- files:
  - Taipei-City-Dashboard-FE/src/views/DashboardView.vue

- summary:
  - 新增 dashboard 專屬 layout profile，對食安儀表板優先套用明確元件跨度配置，取代過度激進的通用自動規則。
  - 將上排摘要卡（地圖、可能中毒食品、致病原因）恢復為一般尺寸，避免巨大 donut 破壞節奏。
  - 保留「月度統計」跨兩欄，以及「攝食場所」高卡設定，讓資料密度較高的圖表有合理空間。

- change-type:
  - Changed

- technical-details:
  - 新增 `DASHBOARD_LAYOUT_PROFILES` 常數，支援：
    - `food_safety_tpe`
    - `food_safety_taipei`
  - `getTileClass()` 先檢查 `contentStore.currentDashboard.index` 是否命中 profile。
  - 若命中 profile，直接依 `item.index` 回傳預設 class；未命中才回退至通用 heuristics。
  - food_safety_tpe 目前配置：
    - `taipei_imap_food` -> default
    - `food_poisoning_food` -> default
    - `food_poisoning_cause` -> default
    - `ntpc_food_factory` -> default
    - `food_poisoning_trend` -> `dashboard-tile--wide`
    - `food_poisoning_place` -> `dashboard-tile--tall`
    - `wholesale_pesticide_inspection` -> default
    - `school_kitchen_imap` -> default

- verification:
  - VS Code 診斷：`get_errors` 檢查 `Taipei-City-Dashboard-FE/src/views/DashboardView.vue`，結果 `No errors found`。
  - 靜態檢查：確認 `getTileClass()` 以 dashboard profile 為優先，未破壞其他 dashboard 的通用規則。

- performance-impact:
  - 僅新增前端條件判斷，效能影響可忽略。
  - 專屬 profile 可避免不必要的大跨度卡片，提高首屏資訊密度與掃讀效率。

- impact-risk:
  - 若 food_safety dashboard 後續增減元件，profile 需同步更新對應 index。
  - 目前為特定 dashboard 寫死版型，屬刻意的產品化設計選擇，而非通用演算法。

- regression-test:
  - 驗證 `food_safety_tpe` 首排三張卡是否恢復等高、無巨大單卡突兀放大。
  - 驗證 `food_poisoning_trend` 仍維持寬卡呈現。
  - 驗證其他非食安 dashboard 仍沿用原本通用規則。

- traceability:
  - Related request: 使用者回報目前版型「大小不對」，要求進一步 UIUX 優化。

- next-actions:
  - 若仍要更精緻，可下一步加入「每個 dashboard 可編排的 layout schema」資料欄位，將目前 profile 從前端硬編碼提升為可配置系統。
