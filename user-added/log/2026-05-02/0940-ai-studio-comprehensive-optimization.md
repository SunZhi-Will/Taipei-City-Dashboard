# AI Studio 全面優化 / AI Studio Comprehensive Optimization

## 2026-05-02 09:40

- objective:
  - 針對深度分析報告揭露的四項風險，執行全面改善：
    1. `confirm()` 在嵌入環境會被攔截，改為 inline 雙確認機制
    2. `saveChatLog` 以每日固定 session 格式（`session_YYYYMMDD`）記錄，不同用戶同天 log 混雜
    3. `AIStudioChatPanel.vue` 有從未被模板呼叫的 `clearChat()` 死碼
    4. AI Agent Tool Calling Loop 上限 `maxLoops = 5` 寫死，無法因應不同部署環境

- files:
  - Taipei-City-Dashboard-FE/src/views/AIStudioView.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-BE/global/global.go
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - **[FE] 雙確認機制取代 `confirm()`（AIStudioView.vue）**
    - 新增 `pendingClear` ref 與 `pendingClearTimer`
    - 第一次點擊：按鈕切換為警告圖示（`warning`）+ 琥珀色脈衝動畫（`icon-btn--pending`），3 秒後自動復原
    - 第二次點擊（3 秒內）：執行清除
    - `onBeforeUnmount` 中清除 timer，防止記憶體洩漏
    - 新增 `@keyframes icon-btn-pulse` 與 `.icon-btn--pending` 樣式
  - **[FE] 修正 `saveChatLog` session ID（aiChatService.js）**
    - 原本以 `session_YYYYMMDD` 當 session ID，導致同一天不同用戶的對話日誌混雜
    - 改為呼叫既有的 `getTwaiSessionId()`，與 TWAI API 使用相同的 `crypto.randomUUID()` 生成的 session ID
    - 效果：同一瀏覽器 session 的所有對話、日誌、TWAI 呼叫均共用同一個可追溯 ID
  - **[FE] 移除死碼 `clearChat()`（AIStudioChatPanel.vue）**
    - 模板中無任何元素綁定 `clearChat()`（清除按鈕已在 AIStudioView.vue 的面板 header 中）
    - 同步移除僅由 `clearChat` 使用的 `clearChatHistory` destructure
  - **[BE] Tool Loop 上限可配置化（global.go + ai_service.go）**
    - `TWCCConfig` struct 新增 `MaxToolLoops int` 欄位
    - 透過環境變數 `TWCC_MAX_TOOL_LOOPS`（預設 `5`）控制
    - `ai_service.go` 改用 `global.TWCC.MaxToolLoops`，並加安全保護（`<= 0` 時 fallback 為 5）

- change-type:
  - Fixed

- technical-details:
  - `pendingClear` 狀態使用 `setTimeout 3000ms` 作為防呆視窗，避免誤觸後長時間等待
  - `getTwaiSessionId()` 已使用 `crypto.randomUUID()` 或 `Date.now()+Math.random()` fallback 生成 12 字元隨機串，符合防猜測要求
  - `MaxToolLoops` 的 `<= 0` 保護防止管理員誤設 `TWCC_MAX_TOOL_LOOPS=0` 導致 agent 完全不執行工具
  - 移除死碼後 `AIStudioChatPanel` 與 `AIStudioView` 的職責分離更清晰：View 管 UI 控制，Panel 僅管對話

- verification:
  - 執行 `get_errors` 對五個修改檔案，均回報「No errors found」
  - 確認 `pendingClear` timer 在 `onBeforeUnmount` 中被清除（檢查 AIStudioView.vue 的 onBeforeUnmount）
  - 確認 `clearChatHistory` 不再出現於 AIStudioChatPanel.vue（grep 驗證）
  - 確認 `TWCC_MAX_TOOL_LOOPS` 環境變數在 global.go 中正確讀取（code review）

- performance-impact:
  - 無效能衝擊；移除 `clearChat` 死碼略微縮減 bundle 大小（< 0.1KB）

- impact-risk:
  - `pendingClear`：3 秒視窗若使用者感覺太短可調整，目前為合理設計範圍
  - session ID 改變：舊日誌（以日期為 key）仍存於資料庫，不受影響；新日誌改以 UUID-based session 存入，可能需要後台查詢條件調整
  - `MaxToolLoops` 預設值不變（5），現有部署無需更動環境變數

- regression-test:
  - 手動測試：點擊清除按鈕一次 → 確認按鈕變為警告狀態；等待 3 秒 → 確認自動復原
  - 手動測試：點擊清除按鈕兩次（3 秒內）→ 確認聊天記錄清除
  - 手動測試：發送對話 → 確認 chatlog API 呼叫的 session 欄位與 /ai/chat/twai 的 session 一致
  - 後端：設置 `TWCC_MAX_TOOL_LOOPS=3` 環境變數 → 驗證 tool loop 最多執行 3 輪

- traceability:
  - 來源：本 session 的 AI Studio 深度分析報告（潛在風險章節）
  - PR/Commit: N/A

- next-actions:
  - 建議監控 chatlog 資料庫中的 session 分布，確認新格式正確聚合
  - 可考慮在後台管理介面顯示 session-level 對話追蹤（目前 `/chatlog/session/:session` 端點已支援）
  - 評估是否需要將 `TWCC_MAX_TOOL_LOOPS` 加入 Docker Compose 環境變數文件
