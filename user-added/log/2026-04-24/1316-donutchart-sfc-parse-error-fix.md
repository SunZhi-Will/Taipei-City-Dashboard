# DonutChart SFC 語法錯誤修正 / Fix DonutChart SFC Parse Error

## 2026-04-24 13:16

- objective:
  - 修正 `DonutChart.vue` 在 Vite 編譯階段出現的 SFC 解析錯誤（Unexpected token, expected ","）。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue

- summary:
  - 移除誤插入到 `chartOptions` 物件中的 `height="100%"` 字串。
  - 還原為合法 JavaScript 物件結構，避免 Vue SFC parser 在 script 區塊中斷。

- change-type:
  - Fixed

- technical-details:
  - 錯誤位置在 `labels: parsedLabels,` 與 `legend:` 之間，多出 template attribute 文本。
  - 刪除該行後，`chartOptions` 物件語法恢復正常。

- verification:
  - `get_errors` 檢查 `Taipei-City-Dashboard-FE/src/dashboardComponent/components/DonutChart.vue` -> No errors found。

- performance-impact:
  - 無，僅語法修正。

- impact-risk:
  - 低風險；不改業務邏輯與渲染策略。

- regression-test:
  - 重新啟動前端編譯流程，確認不再出現 `[vue/compiler-sfc] Unexpected token`。
  - 驗證 Donut 圖表頁面可正常渲染。

- traceability:
  - N/A

- next-actions:
  - N/A
