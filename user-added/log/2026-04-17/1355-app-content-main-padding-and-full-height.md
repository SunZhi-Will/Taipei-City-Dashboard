# 調整 app-content-main 上間距並修正滿高度 / Adjust app-content-main top spacing and full-height behavior

## 2026-04-17 13:55

- objective:
  - 讓 `app-content-main` 保留一點上方間距。
  - 修正主內容區高度未填滿可用空間的問題。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 在 `app-content-main` 新增上方 `padding-top: 8px`，提供輕量上緣留白。
  - 將三種 layout（mapview/dashboard、admin、component）中的 `RouterView` 改包在 `app-content-body` 容器。
  - 以 `app-content-body { flex: 1; min-height: 0; }` 確保內容可吃滿 `app-content-main` 的剩餘高度。

- change-type:
  - Fixed

- technical-details:
  - 修改 template：
    - `SettingsBar` 後的 `RouterView` 包成 `<div class="app-content-body"><RouterView /></div>`。
    - 同步套用於 admin 與 component layout。
  - 修改 scoped SCSS：
    - `app-content-main` 新增 `padding-top: 8px; box-sizing: border-box;`
    - 新增 `app-content-body` 樣式：`flex: 1; min-height: 0;`
  - 設計理由：
    - 單純設定 `height: 100%` 不足以保證子內容撐滿剩餘空間。
    - 透過專屬 body 容器作為 flex grow 區塊，路由頁內容才有穩定可用高度。

- verification:
  - VS Code 問題檢查：
    - `Taipei-City-Dashboard-FE/src/App.vue` -> No errors found
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` -> No errors found
  - 結構檢查：
    - 三種主要 layout 皆已改為 `app-content-body` 包覆 `RouterView`。

- performance-impact:
  - 無顯著效能影響。
  - 僅調整 layout 容器與 CSS，無新增運算或 API 請求。

- impact-risk:
  - 低風險。
  - 若個別路由頁原先依賴外層 margin/padding，視覺密度可能輕微改變。

- regression-test:
  - 建議檢查路由：`/dashboard`、`/mapview`、`/admin`、`/component/:index`。
  - 驗證項目：
    - `app-content-main` 頂部有輕微留白。
    - 主內容區高度可填滿剩餘空間。
    - 捲動行為與側欄對齊正常。

- traceability:
  - N/A

- next-actions:
  - 若希望可調式留白，後續可改為 CSS 變數（例如 `--app-content-top-gap`）集中控管。
