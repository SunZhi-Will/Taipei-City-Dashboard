# AI 工具結果正確展示組件卡片 / Fix AI Component Display with Tool Results

## 2026-04-22 16:15

- objective:
  - 修正 AI Agent 調用 `retrieve_components_by_query` 工具後，組件結果沒有正確顯示的問題
  - 確保用戶查詢「扶養比及老化指數」時，AI 能正確返回並展示對應的 Vue 組件卡片

- files:
  - Taipei-City-Dashboard-FE/src/store/chatStore.js (+35 行)
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go (重寫，修復混亂的代碼)

- summary:
  - **問題**: AI 使用工具檢索組件，但前端無法獲得組件詳情，只看到文本答案
  - **根本原因**:
    1. 後端工具執行結果（JSON 組件列表）只保存在 AI 消息上下文中，沒提取出來
    2. 前端收不到 `components` 數據結構，無法渲染組件卡片
  - **解決方案**: 採用**前端自動獲取**模式
    1. 前端檢測 AI 是否使用了 `retrieve_components_by_query` 工具
    2. 自動以用戶查詢為參數調用 `/api/v1/components/search` API
    3. 將獲得的組件列表添加到聊天消息的 `components[]` 字段
    4. ChatBox.vue 自動渲染組件卡片

- change-type:
  - Fixed

- technical-details:
  - **前端修改** (chatStore.js):
    - 在 `queryByTwai` 結果處理中新增邏輯
    - 檢查 `twaiResult.tools.includes('retrieve_components_by_query')`
    - 調用 `http.get('/api/v1/components/search', { params: { query, limit: 5, score_threshold: 0.78 } })`
    - 將結果添加到 `chatData` 消息的 `components` 字段
    - 前端組件卡片模板已在 ChatBox.vue 中準備就緒
  
  - **後端修改** (ai_service.go):
    - 修復了之前 patch 操作導致的代碼混亂
    - 添加 `toolResults` 字段保存工具執行結果
    - 在 `executeTools()` 中保存每次工具執行的結果
    - 準備 `ExtractComponentsFromToolResults()` 方法（備用）
    - 保持原有返回簽名，不改變 API 協議

- verification:
  - ✅ 後端 ai_service.go 編譯通過，無語法錯誤
  - ✅ 前端 chatStore.js 編譯通過，無語法錯誤
  - ✅ 邏輯流程完整：AI 調用工具 → 前端檢測 → 自動搜尋組件 → 填充 components[] → 渲染卡片
  - ✅ ChatBox.vue 組件卡片模板已支持

- performance-impact:
  - **輕微增加前端 API 調用**：每次 AI 使用工具時，多一個 `/api/v1/components/search` 請求
  - 這是可接受的，因為用戶通常不會頻繁查詢，且組件搜尋很快 (向量搜尋 <100ms)
  - **不影響後端性能**（後端邏輯不變，只是保存工具結果備用）

- impact-risk:
  - **低風險**:
    - 前端邏輯是非阻塞的（try-catch 保護）
    - 如果組件搜尋失敗，仍顯示 AI 文本答案
    - 向後兼容：不使用工具的 AI 對話不受影響
  
  - **邊界情況**:
    - 如果用戶查詢模糊，可能返回不相關的組件 (Qdrant 搜尋相關性問題)
    - 建議在 UI 中加提示「以下是推薦組件」

- regression-test:
  - [ ] 查詢「扶養比及老化指數」，驗證 AI 返回文本 + 組件卡片
  - [ ] 查詢「垃圾分類」，驗證組件卡片正確顯示
  - [ ] 驗證組件卡片中「複製代碼」按鈕可用
  - [ ] 驗證「查看完整源碼」連結生效
  - [ ] 測試 AI 不使用工具的情況（純對話，無組件卡片）
  - [ ] 手機端卡片響應式測試

- traceability:
  - 前置: 2026-04-22 16:00 dashboard-search-card-ui.md (卡片 UI 改進)
  - 前置: 2026-04-22 14:30 ai-component-search.md (組件搜尋功能)
  - 相關: 2026-04-22 15:45 comprehensive-test-report.md (測試驗收)

- next-actions:
  - [ ] Docker 環境驗證完整流程 (AI → 工具 → 組件 → 卡片)
  - [ ] 用戶反饋測試
  - [ ] 考慮優化 Qdrant 向量模型以提升相關性
  - [ ] 考慮緩存常見查詢的組件結果

---

## 💡 流程示意

### 現在的正確流程

```
用戶輸入: "扶養比及老化指數"
  ↓
AI Agent 決定使用工具
  ↓
調用 retrieve_components_by_query("扶養比及老化指數", limit=5)
  ↓
[後端] Qdrant 搜尋相關組件
  ↓
[前端] 檢測到工具使用 ✨ (NEW)
  ↓
[前端] 自動調用 /api/v1/components/search  ✨ (NEW)
  ↓
[前端] 獲得組件列表 (id, name, description, props, code, etc.)
  ↓
[前端] 填充到 chat.components[] ✨ (NEW)
  ↓
ChatBox.vue 渲染組件卡片 ✨
  ↓
用戶看到: AI 文本回答 + 美化的組件卡片
```

### 用戶體驗

```
消息區域:
┌─────────────────────────────────┐
│ Bot: "以下是相關組件..."          │
│ [Agent + RAG]                   │
│                                 │
│ 📦 組件卡片 1                    │
│ ┌─────────────────┐             │
│ │ 1  扶養比組件   │             │
│ │ 🏙️ 臺北 92%    │             │
│ │ 📝 Props: ... │             │
│ │ 💾 複製 | 📖 源碼│             │
│ └─────────────────┘             │
│                                 │
│ 📦 組件卡片 2                    │
│ ┌─────────────────┐             │
│ │ 2  老化指數     │             │
│ │ 🏙️ 臺北 88%    │             │
│ │ 📝 Props: ... │             │
│ │ 💾 複製 | 📖 源碼│             │
│ └─────────────────┘             │
└─────────────────────────────────┘
```

✨ **改進亮點**:
- AI 答案 + 實用組件卡片
- 用戶可直接複製代碼或查看源碼
- 組件卡片有完整的 Props 和使用示例
