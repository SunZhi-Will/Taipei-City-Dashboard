# MapView 編碼修復 / MapView Encoding Fix

## 2026-04-23 14:45

- objective:
  - 修復 MapView.vue 中因編碼錯誤導致的亂碼文字，恢復所有 UI 文案的正確中文顯示。

- files:
  - Taipei-City-Dashboard-FE/src/views/MapView.vue

- summary:
  - 檔案編碼異常造成的亂碼（如 `?惜?郊?批`、`蝘犖?銵冽` 等）已全數修正。
  - 恢復為正確的繁體中文文案。

- change-type:
  - Fixed

- technical-details:
  - 修復位置及內容：
    - `?惜?郊?批` → `圖層同步控制`
    - `蝘犖?銵冽` → `私人儀表板`
    - `?????` → `我的最愛`
    - `?犖?銵冽` → `個人儀表板`
    - `?砍?銵冽` → `公共儀表板`
    - 以及其他相關文字標籤
  - 使用 UTF-8 正確編碼重新保存檔案。

- verification:
  - `get_errors` 檢查 `MapView.vue`：No errors found。
  - 檔案編碼檢驗：無多位元組序列異常。
  - 容器日誌：無新的 Vue SFC 編譯錯誤。

- performance-impact:
  - 無性能影響，純文案修復。

- impact-risk:
  - 低風險：僅修正 UI 文本顯示。

- regression-test:
  - 進入 `/mapview` 確認所有中文文案正常顯示。
  - 檢查各按鈕、標題、下拉菜單的文字是否清晰可讀。

- traceability:
  - Related log: user-added/log/2026-04-23/1441-mapview-sync-split-sfc-fix.md

- next-actions:
  - N/A
