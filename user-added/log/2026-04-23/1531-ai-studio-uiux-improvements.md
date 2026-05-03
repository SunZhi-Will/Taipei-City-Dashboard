# AI Studio 聊天面板 UI/UX 優化 / AI Studio Chat Panel UI/UX Improvements

## 2026-04-23 15:31

- objective:
  - 提升 AI Studio 聊天面板的視覺層次、互動回饋與使用流暢度

- files:
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue

- summary:
  - 新增 Bot 頭像圖示（`smart_toy`）在每則 bot 訊息左側，提升視覺層次
  - 打字指示器加入 "AI 分析中…" 文字標籤與 Bot 頭像，使等待狀態更清楚
  - 新增「捲到最新」浮動按鈕（FAB），當使用者向上捲動超過 120px 時出現，附淡入/淡出動畫
  - 所有訊息列（`acp__row`）加入滑入動畫（`acp-slide-in`），新訊息出現更自然流暢
  - 空狀態圖示加大至 2.4rem 並加入脈動動畫（`acp-pulse`），視覺更吸引
  - Tag chip hover 效果改為 accent 顏色高亮（原本僅亮白色文字）
  - `&__typing` 圓角從 5px 改為 4px 12px 12px 12px，與 bot message block 對齊
  - Bot avatar 樣式：`flex-shrink: 0`、1rem 大小、藍色調色

- change-type:
  - Changed

- technical-details:
  - 新增 `showScrollBtn` ref 與 `onScroll` handler，使用 `@scroll.passive` 事件監聽提升效能
  - `Transition` 組件包裝 scroll FAB，使用 `.acp-fade-enter/leave` CSS transition classes
  - 新增三個 keyframe 動畫：`acp-slide-in`（訊息入場）、`acp-pulse`（空狀態）、已有 `acp-blink` 保留
  - `&__bot-block` max-width 改為 `calc(100% - 32px)` 以正確預留頭像空間
  - `.acp` 根元素加入 `position: relative` 以支援 FAB 的 `position: absolute` 定位
  - `&__row--bot` 加入 `align-items: flex-start; gap: 8px` 讓頭像與訊息內容頂端對齊

- verification:
  - 使用 VS Code 語言服務檢查，回報 No errors found
  - 檢查所有 `rgba($accent, ...)` 用法與既有程式碼一致（參照 `&__action-btn`、`&__user-bubble`）

- performance-impact:
  - `@scroll.passive` 避免阻塞瀏覽器捲動事件
  - CSS animation 使用 transform/opacity，由 GPU 合成，不觸發 layout reflow

- impact-risk:
  - 低風險：僅修改同一元件的樣式與模板，無邏輯/API 變動
  - FAB 按鈕 `z-index: 10` 需確認不與其他浮層衝突

- regression-test:
  - 驗證項目：Bot 訊息顯示頭像、打字中顯示頭像與標籤、捲動時 FAB 出現/消失、Tag hover 顏色
  - 驗證空狀態（無對話時）圖示脈動動畫正常播放
  - 確認 clear chat 功能後空狀態正確顯示

- traceability:
  - N/A

- next-actions:
  - P2：考慮加入 bot 訊息 copy 按鈕（hover 顯示）
  - P3：考慮使用 `<TransitionGroup>` 取代純 CSS 動畫以更精確控制進場
