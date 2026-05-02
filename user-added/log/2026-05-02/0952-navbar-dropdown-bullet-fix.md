# 修正導覽列下拉選單圓點外溢 / Fix Navbar Dropdown Bullet Overflow

## 2026-05-02 09:52

- objective:
  - 修正導覽列資訊下拉選單在左側出現超出區塊的預設清單圓點問題，避免 UI 視覺瑕疵。

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue
  - user-added/log/2026-05-02/0952-navbar-dropdown-bullet-fix.md

- summary:
  - 在導覽列下拉選單的 `ul` 補上 `margin: 0` 與 `list-style: none`，移除瀏覽器預設清單 marker。
  - 在下拉選單的 `li` 補上 `list-style: none` 作為雙保險，避免外部樣式影響造成 marker 回復。
  - 本次修改屬於最小範圍 CSS 調整，不影響既有互動行為（hover 顯示、定位、間距）。

- change-type:
  - Fixed

- technical-details:
  - 修改位置為 `.navbar-user-user, .navbar-user-info` 內的下拉 `ul` 規則區塊。
  - 新增樣式如下：
    - `ul`: `margin: 0; list-style: none;`
    - `li`: `list-style: none;`
  - 目的是覆蓋 `li` 預設 `display: list-item` 的 marker 呈現，消除左側外溢圓點。

- verification:
  - 以指令檢查樣式已寫入：
    - `grep -n "list-style\|margin: 0;" Taipei-City-Dashboard-FE/src/components/utilities/bars/NavBar.vue | head -n 20`
  - 檢查結果包含以下關鍵行：
    - `margin: 0;`
    - `list-style: none;`（`ul` 與 `li` 各一處）

- performance-impact:
  - 無可量測效能影響。
  - 僅樣式層級修正，渲染成本變化可忽略。

- impact-risk:
  - 影響範圍限定於導覽列資訊/使用者下拉選單的清單呈現。
  - 低風險：僅移除清單 marker，不變更事件或 DOM 結構。
  - 已知邊界：若未來設計需在該選單使用原生清單符號，需再局部覆寫。

- regression-test:
  - 驗證桌機版導覽列：
    - 滑入資訊按鈕，下拉選單不應出現左側圓點。
    - 滑入使用者按鈕，下拉選單不應出現左側圓點。
  - 驗證窄螢幕條件下 `.navbar-user-info` 的定位與顯示不受影響。

- traceability:
  - N/A

- next-actions:
  - N/A
