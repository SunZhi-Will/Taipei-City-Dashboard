# 修正 AI Studio 簡報畫布 Sass 背景語法錯誤 / Fix AI Studio Presentation Canvas Sass Background Syntax Error

## 2026-04-24 11:14

- objective:
  - 修復 `AIStudioPresentationCanvas.vue` 的 Sass 編譯錯誤（`expected ";"`），使 Vite 能正常編譯樣式。

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - user-added/log/2026-04-24/1114-ai-studio-sass-background-fix.md

- summary:
  - 移除四個產業主題樣式中重複的 `background:` 宣告。
  - 保留原有 radial-gradient 設計，僅做語法層最小修正，避免視覺回歸。

- change-type:
  - Fixed

- technical-details:
  - 問題根因：在 `.presentation-canvas.industry-transport`、`.industry-senior-care`、`.industry-education`、`.industry-health` 區塊內，`background:` 後又重複 `background:`，導致 Sass parser 在屬性值位置中斷。
  - 修正方式：將重複內層 `background:` 移除，改為單一合法屬性搭配多層漸層值。
  - 影響範圍：僅限 AI Studio 簡報畫布主題背景樣式。

- verification:
  - 執行 VS Code 診斷檢查：`get_errors` 針對 `Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue` 回傳 `No errors found`。
  - 對照使用者錯誤訊息位置（Sass line 27）確認已移除造成解析失敗的語法。

- performance-impact:
  - 無顯著效能變動。
  - 僅為樣式語法修正，渲染負擔不變。

- impact-risk:
  - 低風險：未變更樣式語意與元件邏輯。
  - 已知邊界：若外部主題系統覆寫 `background`，視覺仍可能因覆寫規則而不同，與本次修正無關。

- regression-test:
  - 建議在本機執行前端啟動流程並切換 AI Studio 產業主題，確認四種主題背景可正常顯示。
  - 建議檢查 `transport/senior-care/education/health` 主題切換時無白屏或樣式丟失。

- traceability:
  - Related error report: `[plugin:vite:css] [sass] expected ";"` at `AIStudioPresentationCanvas.vue 27:13`
  - Commit/PR: N/A

- next-actions:
  - N/A
