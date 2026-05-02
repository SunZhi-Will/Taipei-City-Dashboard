# 右下角聊天 Widget 全面實作（可近用性與行動版強化） / Full Implementation of Bottom-Right Chat Widget (Accessibility and Mobile Hardening)

## 2026-04-21 17:33

- objective:
  - 依據 UI/UX 深度分析，全面實作右下角 Chat Bot 的 P0/P1 改善項目。
  - 目標包含可近用性（a11y）、鍵盤操作、行動版適配、錯誤體驗與內容安全。

- files:
  - widget-demo-clean/aichathub-widget-v2.js
  - widget-demo-clean/index.html

- summary:
  - 在 widget 腳本中加入可近用性屬性（launcher/panel/input/header actions 的 aria 標記）。
  - 補上鍵盤操作能力：Esc 關閉聊天面板、回報問題 modal 的 Esc 與 focus trap。
  - 新增行動版斷點樣式（mobileBreakpoint），改善小螢幕下 panel 尺寸、間距與輸入區可用性。
  - 對 assistant markdown 輸出加入 HTML 淨化處理，移除危險標籤與事件屬性。
  - 優化錯誤文案與回饋失敗提示（toast）。
  - 在 demo config 顯式加入 mobileBreakpoint 參數。

- change-type:
  - Changed

- technical-details:
  - 新增 `G()` HTML 淨化函式：移除 `script/iframe/object/embed/style`，過濾 `on*` 屬性與 `javascript:`/`data:text/html` 連結來源。
  - `parseMarkdown()` 在渲染後統一經過淨化再注入 message 區塊。
  - `createPanel()` 補齊 `role=dialog`、`aria-hidden` 與面板生命週期同步切換。
  - `setupEvents()` 增加 Esc 快捷關閉邏輯（有回報 modal 時不關閉主面板，避免衝突）。
  - CSS 內加入 `@media (max-width: mobileBreakpoint)`，強化 mobile 可視範圍與操作觸控面積。

- verification:
  - 檔案層檢查：確認 `widget-demo-clean/aichathub-widget-v2.js` 出現 `aria-label`、`mobileBreakpoint`、`@media`、`G(`、`widget_closed_by_escape`。
  - 設定檢查：確認 `widget-demo-clean/index.html` 已加入 `mobileBreakpoint: 768`。
  - 變更完整性檢查：本 log 已列出所有修改檔案與技術細節。

- performance-impact:
  - HTML 淨化為每次 assistant 訊息渲染增加一次 DOM template 遍歷，對單則訊息有輕微 CPU 開銷。
  - 響應式 CSS 為純樣式層，不增加網路資源。

- impact-risk:
  - 中低風險：屬於前端互動與樣式層修改，主要風險為極端 HTML 內容被過度清洗造成顯示差異。
  - 已知邊界：若未來需要允許更複雜內嵌 HTML，需擴充白名單策略。

- regression-test:
  - 桌面版：開啟/關閉 widget、輸入送出、Tag 點擊、地圖與圖表全屏、回報問題 modal 開關。
  - 鍵盤測試：Tab 導覽、Enter 送出、Esc 關閉（主面板與 modal）。
  - 行動版：小於 768px viewport 下版面與輸入區操作。
  - 安全測試：assistant 回覆含 `<script>` 與 `onerror` 屬性時應被清除。

- traceability:
  - N/A

- next-actions:
  - P1: 將「重新嘗試」按鈕加入錯誤訊息卡片。
  - P1: 補齊 E2E 自動化測試（a11y + mobile 主要路徑）。
