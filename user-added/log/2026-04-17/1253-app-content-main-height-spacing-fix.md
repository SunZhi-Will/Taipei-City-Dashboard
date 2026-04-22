# 修正 app-content-main 滿高度與子層上下間距 / Fix app-content-main full-height and child vertical spacing

## 2026-04-17 12:53

- objective:
  - 修正主內容區塊未滿高度的版面問題。
  - 移除 app-content-main 下一層（直屬子層）的上下間距，避免視覺空隙。

- files:
  - Taipei-City-Dashboard-FE/src/App.vue

- summary:
  - 在 app-content-main 新增 `height: 100%` 與 `min-height: 0`，確保在 flex 版面中可正確撐滿可用高度。
  - 針對 app-content-main 直屬子元素新增上下 margin 歸零規則，避免內層元件預設 margin 造成上下留白。

- change-type:
  - Fixed

- technical-details:
  - 變更位置：`<style scoped lang="scss">` 的 `.app-content-main` 區塊。
  - 新增屬性：
    - `height: 100%;`
    - `min-height: 0;`
  - 新增 selector：
    - `> * { margin-top: 0; margin-bottom: 0; }`
  - 設計考量：
    - 在巢狀 flex 佈局中，`min-height: 0` 可避免子容器高度計算導致的 overflow/無法貼齊問題。
    - 只限制直屬子層的垂直 margin，避免不必要擴散到更深層內容。

- verification:
  - 使用 VS Code 診斷檢查目標檔案：`Taipei-City-Dashboard-FE/src/App.vue`（No errors found）。
  - 內容檢查：確認 `.app-content-main` 已包含 `height: 100%`、`min-height: 0` 與 `> *` 的上下 margin 歸零設定。

- performance-impact:
  - 無顯著效能影響。
  - 僅為 CSS 版面規則微調，預期渲染成本變化可忽略。

- impact-risk:
  - 風險：若某些直屬子元件原本仰賴外層 margin 產生上下留白，可能視覺上更緊密。
  - 緩解：目前僅作用於 `app-content-main` 的下一層，範圍受控；必要時可於個別元件內改用 padding 重建需求間距。

- regression-test:
  - 建議檢查路由：`/mapview`、`/dashboard`、`/admin`、`/component/:index`。
  - 建議檢查裝置：桌機寬螢幕與手機窄螢幕（含旋轉）。
  - 建議檢查項目：
    - 主內容是否滿高。
    - SettingsBar 與主內容區是否仍有非預期上下空隙。
    - 內容捲動是否正常。

- traceability:
  - N/A

- next-actions:
  - 若仍有單一路由頁面出現留白，進一步針對該頁 root 容器補 `height: 100%` 或調整內層 padding。
