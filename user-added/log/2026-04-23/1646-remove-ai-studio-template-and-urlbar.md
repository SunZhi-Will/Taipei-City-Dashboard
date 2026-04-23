# 移除 AI Studio 模板與網址列功能 / Remove AI Studio Template and URL Bar Features

## 2026-04-23 16:46

- objective:
  - 移除 AI Studio 左側「場景模板」功能區塊與右側 Web 模式網址輸入列，簡化畫面與操作流程。

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue

- summary:
  - 刪除左側面板中的「場景模板」整段 UI（含開闔、儲存模板、套用與刪除按鈕區塊）。
  - 移除與模板區塊相關的 state 與方法（templateName、templatePanelOpen、save/apply/remove template handler）。
  - 刪除右側 Web 模式的網址列 UI（web-urlbar / web-urlinput），保留 iframe 顯示機制。
  - 同步清理不再使用的 SCSS 樣式，避免殘留死碼。

- change-type:
  - Fixed

- technical-details:
  - `storeToRefs(aiStudioStore)` 從 `{ scene, templates }` 調整為僅保留 `{ scene }`。
  - 移除模板相關函式與綁定，避免出現未使用變數或方法。
  - 保留 `webUrlInput` 供現有 web iframe `src` 與 `title` 使用，僅移除可編輯 URL 的輸入 UI。
  - 刪除 `.tpl-*` 與 `.web-url*` SCSS 區塊，保持樣式結構一致。

- verification:
  - 文字搜尋確認目標區塊來源：
    - 指令：`grep_search query="tpl-section|tpl-toggle|場景模板|web-urlbar|web-urlinput" includePattern="Taipei-City-Dashboard-FE/src/**/*.vue"`
    - 結果：目標位於 `Taipei-City-Dashboard-FE/src/views/AIStudioView.vue`。
  - 語法/診斷檢查：
    - 指令：`get_errors file=Taipei-City-Dashboard-FE/src/views/AIStudioView.vue`
    - 結果：No errors found。

- performance-impact:
  - DOM 節點與樣式規則小幅減少，渲染負擔微幅降低。
  - 無額外 API 呼叫與運算成本增加。

- impact-risk:
  - 使用者將無法在 UI 直接儲存/套用/刪除場景模板。
  - 使用者將無法在 UI 直接輸入自訂網址；Web 模式改為使用既有 `webUrlInput` 預設值來源。
  - 目前未修改 store 端模板能力，若其他頁面仍依賴相關能力不受影響。

- regression-test:
  - 驗證 AI Studio 頁面可正常載入與聊天。
  - 驗證左側不再顯示「場景模板」區塊。
  - 驗證 Web 模式不再顯示網址輸入列且 iframe 可正常顯示。
  - 驗證 components/map 模式切換不受影響。

- traceability:
  - request: 使用者指示移除 `tpl-section` 與先前 `web-urlbar` 功能區塊。

- next-actions:
  - N/A
