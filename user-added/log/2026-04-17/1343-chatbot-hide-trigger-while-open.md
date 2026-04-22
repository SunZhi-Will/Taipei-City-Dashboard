# Chat 展開時隱藏右下角主按鈕 / Hide Chat Trigger While Window Is Open

## 2026-04-17 13:43

- objective:
  - 調整右下角 Chat 互動行為：展開聊天視窗後，右下角圓形 ChatBot 按鈕應隱藏。
  - 讓畫面只保留聊天視窗，避免視覺重疊與重複入口。

- files:
  - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue

- summary:
  - 在聊天主按鈕容器 `chatbot-btn-area` 新增 `v-if="!isChatOpen"` 條件。
  - 當 `isChatOpen=true` 時，主按鈕不渲染；僅顯示 ChatBox。
  - 保留既有關閉方式（ChatBox 關閉按鈕與 Esc）。

- change-type:
  - Changed

- technical-details:
  - 變更點為 template 層，不涉及 store 或 API。
  - 採條件渲染而非樣式隱藏，避免多餘可互動元素殘留。

- verification:
  - VS Code diagnostics:
    - Taipei-City-Dashboard-FE/src/components/chat/ChatWidgetLauncher.vue -> No errors found

- performance-impact:
  - 影響極低。
  - 展開聊天時會少渲染一個按鈕容器，對 DOM 輕微減量。

- impact-risk:
  - 低風險，僅影響 Chat 啟動器視覺顯示時機。
  - 若未來移除 ChatBox 關閉按鈕，需同步調整關閉路徑。

- regression-test:
  - 點右下角 Chat 主按鈕後，確認：
    - Chat 視窗出現。
    - 右下角圓形 ChatBot 按鈕消失。
  - 關閉 Chat 視窗後，確認主按鈕重新出現。
  - 測試 Esc 關閉行為維持正常。

- traceability:
  - related-log:
    - user-added/log/2026-04-17/1341-chatbot-remove-minimize-and-restore-buttons.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions:
  - P1: 若希望更明顯，可在視窗開啟時加入短暫入場動畫，降低視覺跳動感。
