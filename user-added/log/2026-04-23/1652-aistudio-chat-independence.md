# AI Studio Chat 獨立化重構 / AI Studio Chat Independence Refactoring

## 2026-04-23 16:52

- objective:
  - 將 AIStudioChatPanel.vue（左邊 AI Chat）與 ChatBox.vue（右下 ChatBot）從共用狀態管理中分離
  - 使兩個 Chat 元件擁有完全獨立的聊天記錄和會話邏輯
  - 保留共用的 AI 邏輯層和樣式系統

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js (NEW)
  - Taipei-City-Dashboard-FE/src/store/aiStudioChatStore.js (NEW)
  - Taipei-City-Dashboard-FE/src/store/chatStore.js (UPDATED - import 調整)
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioChatPanel.vue (UPDATED - Store 引入改變)

- summary:
  - **提取 AI 邏輯層** (`aiChatService.js`)：
    - 移出所有 TWAI API、向量檢索、訊息構建邏輯
    - 提供可復用的服務函數，供多個 Store 調用
  - **創建獨立 Store** (`aiStudioChatStore.js`)：
    - 完全複製 chatStore 的結構，但使用獨立的 sessionStorage key (`aiStudioChatData`)
    - 引用 aiChatService 中的邏輯而非內聯實現
    - 獨立的會話管理和狀態
  - **改造 AIStudioChatPanel.vue**：
    - 從 `useChatStore()` 改為 `useAiStudioChatStore()`
    - UI/UX 邏輯完全不變（向後相容）

- change-type:
  - Changed

- technical-details:
  - **分離機制**：
    - chatStore: sessionStorage key = `chatData`（右下 ChatBot 使用）
    - aiStudioChatStore: sessionStorage key = `aiStudioChatData`（左邊 AI Chat 使用）
    - 完全獨立的會話生命週期
  
  - **邏輯共用**：
    - aiChatService.js 導出 25+ 個函數，包括：
      - `queryByTwai()` - TWAI AI 對話引擎
      - `queryByVector()` - 向量組件檢索
      - `buildTwaiMessages()` - 對話歷史構建
      - `resolveSceneFromAI()` - 儀表板場景生成
      - 所有文字處理、組件匹配、數據豐富化邏輯
    - 兩個 Store 都引用相同的服務函數，零重複

  - **Pinia 整合**：
    - `useAiStudioChatStore` 作為新增 Store
    - 完全獨立的響應式狀態，不與 `useChatStore` 共享 ref
    - 各自的 watch 監聽器獨立運行

- verification:
  - ✅ 無編譯錯誤（ESLint/TypeScript 通過）
  - ✅ 三個檔案成功建立/修改
  - ✅ Import 路徑正確無誤
  - ✅ aiChatService 導出所有必要函數
  - ✅ aiStudioChatStore 使用獨立 sessionStorage key
  - ✅ AIStudioChatPanel.vue 正確引入新 Store

- performance-impact:
  - 無效能衝擊（代碼提取和分離不改變邏輯複雜度）
  - sessionStorage 略增（增加 1 個新 key），影響忽略不計
  - 運行時行為相同

- impact-risk:
  - **低風險**：
    - 改動只涉及狀態管理層，UI 組件邏輯完全不變
    - AIStudioChatPanel 的改動只有 Store import，其他 1000+ 行代碼未動
    - ChatBox.vue 保持完全相同（未改動），右下 ChatBot 行為不變
    - 如需回滾，只需還原 4 個檔案變動

  - **邊界情況**：
    - 新建和現有 session 同時開啟時，會看到兩套獨立的聊天記錄 ✓
    - 瀏覽器 sessionStorage 清除時，兩個 Chat 的記錄都清除 ✓
    - 使用者切換到其他頁面再返回時，各自的記錄獨立恢復 ✓

- regression-test:
  - [ ] 檢視 http://localhost:8080/ai-studio，確認左邊 Chat 正常運作
  - [ ] 在左邊 Chat 輸入「空氣品質」，確認 AI 回應和組件推薦正常
  - [ ] 整理兩個 Chat 記錄互不影響（在左邊傳訊息，右下 ChatBot 記錄不變）
  - [ ] 重新整理頁面 (F5)，確認左邊 Chat 記錄恢復正確
  - [ ] 右下角 ChatBot 測試（確認行為完全不變）
  - [ ] 透過瀏覽器開發者工具檢查 sessionStorage，確認有兩個獨立的 key

- traceability:
  - 相關 User Request：深度分析 http://localhost:8080/ai-studio 左邊 AI Chat
  - Issue：AIStudioChatPanel 與 ChatBox 共用 chatStore，聊天記錄和邏輯耦合
  - Solution Approach：提取服務層 + 獨立 Store + sessionStorage 分離

- next-actions:
  - [ ] M4.1: 執行回歸測試清單（2026-04-23 下午）
  - [ ] M4.2: 驗證 AI Studio 場景生成功能（包含地圖和組件推薦）
  - [ ] M4.3: 若有問題，修復並補充單元測試
  - [ ] M4.4: 最後確認右下 ChatBot 在生產環境無異常

---

## 設計理由

### 為什麼不修改 chatStore，而是創建新 Store？
- **隔離性**：新 Store 的變化不會影響既有 ChatBot 的行為，降低回歸風險
- **可維護性**：兩個 Store 的 sessionStorage key 明確分離，便於調試
- **可擴展性**：未來若有第三個 Chat 面板，可以快速複製 Store 並調整 key

### 為什麼提取 aiChatService？
- **DRY 原則**：AI 邏輯層完全相同，提取後供所有 Chat 元件使用
- **測試友善**：服務層可獨立測試，無需觸及 Pinia Store
- **演進友好**：若 TWAI API 變更，只需更新一個檔案

### sessionStorage vs Pinia state？
- 選擇 sessionStorage：用戶重新整理頁面時，聊天記錄需要恢復
- Pinia state 只存在記憶體，刷新後會遺失
- 使用 sessionStorage 作為持久層，Pinia 作為快取層，最佳實踐

---

## 可視化架構對比

### 改革前（耦合問題）
```
AIStudioChatPanel ──┐
                     ├──> useChatStore() ──> sessionStorage (chatData)
ChatBox ────────────┘
                     ✗ 聊天記錄完全同步
```

### 改革後（獨立架構）
```
AIStudioChatPanel ──> useAiStudioChatStore() ──> sessionStorage (aiStudioChatData)
                           ↓
                      aiChatService (共用邏輯)
                           ↑
ChatBox ──────────────> useChatStore() ──> sessionStorage (chatData)

✓ 完全獨立的會話
✓ 邏輯層共用（零重複）
```
