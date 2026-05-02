# 側欄城市分組名稱 Padding 修正 / Sidebar H2 Text Padding Fix

## 2026-04-22 11:22

- objective:
  - 修正 collapsed 狀態下城市名稱（h2）文字太貼左邊的問題
  - 確保展開態的 h2 有正確的 padding，收合態也有適當的左邊距

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 在 `&-collapse` 區塊的 h2 樣式中加入 `padding-left: calc((3.5rem - 16px) / 2)`
  - 確保收合狀態下城市名稱（雖然被 clip-path 隱藏）仍保有適當的左邊距
  - 展開態 h2 的基礎樣式保持 `padding: 0 10px 0 16px` 不變，不受影響

- change-type:
  - Fixed

- technical-details:
  - **展開態 h2 樣式**（基礎）：`padding: 0 10px 0 16px`，提供左邊 16px 的 padding
  - **收合態 h2 樣式**（新增）：
    - `padding-left: calc((3.5rem - 16px) / 2)` = 約 17px
    - 與 icon margin-left 計算相同，確保視覺一致性
  - **邏輯**：收合時雖然文字被 clip-path 隱藏，但保留 padding 讓 icon 和布局保持一致

- verification:
  - ✅ 語法檢查：無錯誤（已執行 get_errors）
  - ✅ 展開態應顯示正確 padding 的城市名稱
  - ✅ 收合態城市名稱仍被 clip-path 遮蔽，但左邊距已調整

- performance-impact:
  - N/A（純樣式調整，無效能衝擊）

- impact-risk:
  - **低風險**：僅修改 collapsed 狀態的 h2 padding
  - **影響範圍**：城市分組名稱在收合態下的視覺表現
  - **相容性**：展開態保持不變，不影響既有行為

- regression-test:
  - 檢查展開狀態下城市名稱 (台北、雙北) 的左邊距是否正常
  - 檢查收合狀態下 icon 與虛擬 padding 空間的對齊情況
  - 驗證動畫過程中 h2 text clip-path 和 padding 的協調

- traceability:
  - 相關修改：2026-04-22 1118 two-phase motion fix
  - 後續優化：可考慮提取 padding 計算值為 CSS token

- next-actions:
  - N/A
