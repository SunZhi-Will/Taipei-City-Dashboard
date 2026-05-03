# 移除 app-content-main 底部間距 / Remove bottom spacing in app-content-main

## 2026-04-17 13:58

- objective:
  - 讓主內容區底部不再出現留白。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 在 `app-content-main` 明確補上 `padding-bottom: 0`。
  - 在 `app-content-body` 新增 `padding-bottom: 0`、`margin-bottom: 0`。
  - 對 `app-content-body` 的直屬子層補上 `margin-bottom: 0` 與 `padding-bottom: 0`，避免路由頁根節點帶入底部空白。

- change-type:
  - Fixed

- technical-details:
  - 修改區塊：`<style scoped lang="scss">` 內 `.app-content-main` 與 `.app-content-body`。
  - 新增規則：
    - `.app-content-main { padding-bottom: 0; }`
    - `.app-content-body { padding-bottom: 0; margin-bottom: 0; }`
    - `.app-content-body > * { margin-bottom: 0; padding-bottom: 0; }`
  - 目的：在保留頂部微間距設計前提下，確保底部完全貼齊。

- verification:
  - VS Code 診斷檢查：`Taipei-City-Dashboard-FE/src/App.vue`（No errors found）。
  - 規則檢查：確認 `app-content-main` 與 `app-content-body` 已包含底部歸零設定。

- performance-impact:
  - 無顯著效能影響，僅 CSS 版面規則微調。

- impact-risk:
  - 低風險。
  - 若個別頁面原本依賴根層 `padding-bottom` 作為安全留白，視覺可能更緊貼容器底緣。

- regression-test:
  - 建議檢查路由：`/dashboard`、`/mapview`、`/admin`、`/component/:index`。
  - 驗證項目：底部無留白、內容捲動區正常、頂部 8px 間距仍存在。

- traceability:
  - N/A

- next-actions:
  - 若個別頁面仍有底部空白，優先檢查該頁 root 容器（view 元件）是否另有 `padding-bottom` 或 `margin-bottom`。
