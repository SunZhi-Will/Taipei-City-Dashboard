# 地圖側欄元件結構修復與拆分收斂 / Map Layer Sidebar SFC Repair and Split Consolidation

## 2026-04-23 17:57

- objective:
  - 修復 `MapLayerSidebarContent.vue` 因檔案重複拼接造成的 Vue SFC 結構錯誤（缺少 end tag 與區塊污染）。
  - 收斂側欄元件結構，確保模板僅承擔視圖組裝，邏輯透過既有 composable 與子元件拆分。

- files:
  - Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue

- summary:
  - 將受污染的 `MapLayerSidebarContent.vue` 重建為單一合法 SFC（1 組 script/template/style）。
  - 保留與落實拆分架構：主元件僅負責群組與區塊排版，列表渲染由 `MapDashboardListSection.vue`，狀態與互動邏輯由 `useMapLayerSidebarContent.js`。
  - 以最小行為變更為原則，維持原有互動事件（dashboard-click / component-toggle）與資料流。

- change-type:
  - Fixed

- technical-details:
  - 移除檔案中重複拼接的多組 `<script setup> / <template> / <style>` 區塊，避免 Vite Vue parser 在中段遇到未封閉節點。
  - 主模板只保留：私人儀表板區塊、公共儀表板區塊、城市切換按鈕與子元件串接。
  - 樣式保留既有視覺語意，對子元件節點使用 `:deep(...)` 維持 scoped CSS 可見性。

- verification:
  - 結構檢查指令：
    - `Select-String -Path "Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue" -Pattern '^<template>|^</template>|^<script|^</script>|^<style|^</style>'`
    - 結果僅 6 筆：`<script setup>`, `</script>`, `<template>`, `</template>`, `<style ...>`, `</style>`。
  - 行數檢查指令：
    - `(Get-Content "Taipei-City-Dashboard-FE/src/components/map/MapLayerSidebarContent.vue" | Measure-Object -Line).Lines`
    - 結果：`293`（由污染狀態的大量重複行數回落）。
  - 編輯器診斷：
    - `MapLayerSidebarContent.vue`：No errors found。
    - `MapDashboardListSection.vue`：No errors found。
    - `useMapLayerSidebarContent.js`：No errors found。

- performance-impact:
  - 無演算法層級變更；主要改善為編譯解析穩定性與維護成本下降。
  - 由於移除重複模板與樣式區塊，可減少開發期 HMR/編譯時的解析負擔。

- impact-risk:
  - 風險低：以結構修復為主，事件名稱與資料接口維持不變。
  - 仍需在實際地圖頁驗證「展開儀表板 + 勾選圖層」互動流程，避免受舊髒資料狀態影響。

- regression-test:
  - 開啟地圖頁，確認側欄可正常顯示私人/公共儀表板。
  - 依序測試：
    - 展開私人儀表板（最愛、個人）。
    - 切換公共城市（taipei / metrotaipei）。
    - 勾選與取消勾選組件，檢查圖層是否同步開關。
  - 驗證無再次出現 `[plugin:vite:vue] Element is missing end tag`。

- traceability:
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - 建議補一個簡單靜態檢查腳本，於 CI 檢測 `.vue` 檔案是否含多重頂層 SFC 區塊。
