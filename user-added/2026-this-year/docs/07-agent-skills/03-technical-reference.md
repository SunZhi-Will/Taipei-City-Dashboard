# 技術參考 - Agent & Skill 完整指南

**日期**: 2026-04-14  
**對象**: 開發者、Tech Lead  
**等級**: Internal (Technical)

---

## 📚 什麼是 Agent Skill?

### 定義
Agent Skill 是 VS Code Copilot 的**可複用工作流程模組**，包含：

```yaml
name:        skill 識別符 (檔案夾名稱)
description: "Use when: [觸發條件]"  # 決定何時自動載入
applyTo:     "**/*.go"              # 檔案模式 (glob)
---
[工作流程內容]:
- 階段化決策樹
- 檢查清單
- 程式碼範本
- 最佳實踐
- 資產 (腳本、範本、圖檔)
```

### Skill vs 其他工具

| 特性 | Skill | Instruction | Prompt | Hook |
|-----|--------|-------------|--------|------|
| **何時觸發** | 用戶選擇 (/) | 自動 (全局) | 對話中 | 自動 (文件管道) |
| **範圍** | 特定功能領域 | 專案全局規則 | 單一任務 | 生命週期事件 |
| **資產** | ✅ 帶範本/腳本 | ❌ | ❌ | ❌ |
| **複雜度** | 高 (多步) | 中 | 低 | 中 (Shell) |
| **適合場景** | 完整工作流程 | 編碼風格規則 | 快速問答 | CI/CD 前置檢查 |

---

## 🏗️ Skill 結構

### 標準目錄佈局

```
.github/skills/
├── backend-api-development/
│   ├── SKILL.md                 # ⭐ 核心 Skill 定義
│   ├── templates/
│   │   ├── controller-template.go
│   │   ├── service-template.go
│   │   └── model-template.go
│   ├── checklists/
│   │   ├── design-review.md
│   │   ├── code-review.md
│   │   └── security-checklist.md
│   └── references/
│       ├── best-practices.md
│       ├── decision-tree.md
│       ├── error-handling.md
│       └── cache-strategies.md
│
├── frontend-component-development/
│   ├── SKILL.md
│   ├── templates/
│   │   ├── component-template.vue
│   │   ├── store-module-template.js
│   │   └── test-template.spec.js
│   └── references/
│       ├── component-patterns.md
│       ├── state-mgmt-guide.md
│       └── testing-strategy.md
│
└── [其他 Skill...]
```

### SKILL.md 完整結構

```markdown
---
name: backend-api-development                      # 檔案夾名稱 (必須相符)
description: "Use when: [觸發短語, 2-3 個場景]"   # 決定何時自動載入 ⭐
applyTo: "Taipei-City-Dashboard-BE/**"             # 檔案模式 (glob)
---

# [Skill 標題]

## 目標與里程碑
[表格: M1, M2, M3 與 KPI]

## 工作流程
### Phase 1: [階段名稱]
### Phase 2: ...
### Phase N: 驗收與監控

## 決策樹
[決策流程圖或表格]

## 最佳實踐
[技術決策與理由]

## 範本與檢查清單
[可複用的程式碼範本、檢查清單]

## 常見問題
```

---

## 🎬 如何寫一個 Skill？

### Step 1: 確定需求 (15分)

**問題清單**:
```
□ 這個工作流程適用於多少個場景？ (10+ → 考慮 Skill)
□ 每次都要重複多少個決策點？ (5+ → 值得 Skill)
□ 涉及多少個檔案類型？ (3+ → 複雜度高，適合 Skill)
□ 有沒有相同的最佳實踐、檢查清單？ (是 → 可沈澱)
□ 新人會不會重複犯同樣的錯誤？ (是 → Skill 可預防)
```

**決策樹**:
```
需要嗎？(自我評估)
├─ 不確定? → 先當 Instruction 試試
├─ 是! (5+ 場景 + 3+ 決策) → 繼續 Step 2
└─ 否 → 用 Prompt 或 Instruction 即可
```

### Step 2: 收集知識 (2-3 小時)

**資料來源**:
1. **既有程式碼範例** - 盤點 5-10 個 "好" 的例子
2. **最佳實踐文件** - 內部 wiki、文檔、設計審查紀錄
3. **代碼審查反饋** - PR comments, 常見錯誤
4. **技術決策記錄** (ADR) - 為什麼選這個而不是那個
5. **團隊訪談** - 資深工程師的隱性知識

**輸出物**:
- 反面案例 × 5
- 正面案例 × 5
- 決策點 × 5-10 個
- 快速檢查清單 (checklist)

### Step 3: 草稿 SKILL.md (2-3 小時)

**框架**:

```markdown
---
name: [skill-name]
description: "Use when: [trigger phrase 1], [trigger phrase 2], [trigger phrase 3]"
applyTo: "[glob pattern]"
---

# [Skill 標題]

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1 | [設計/分析階段 goal] | [可量化指標] | P0/P1 |
| M2 | [實現階段 goal] | [可量化指標] | P0 |
| M3 | [優化/驗收 goal] | [可量化指標] | P1 |

## 🔄 工作流程

### Phase 1: [分析/設計]
```
1. 確認需求
   ├─ 用戶故事
   ├─ 資料模型
   └─ API Contract

2. 設計檢查
   ├─ 是否有類似實現？ (複用)
   ├─ 架構是否符合標準？
   └─ 有沒有潛在風險？
```

### Phase 2: [實現]
```
3. 實現 [Component A]
4. 實現 [Component B]
5. [單元測試/整合測試]
```

### Phase 3: [驗收]
```
6. 程式碼審查檢查清單
7. 效能驗收
8. 安全審查
```

## 💡 決策樹

### 選擇 [決策點 1]?
```
條件 A (場景 1)
├─ YES → 用 [Option A, 理由]
└─ NO → 用 [Option B, 理由]
```

## ✅ 檢查清單

### 程式碼審查檢查清單
- [ ] [檢查項 1]
- [ ] [檢查項 2]
- [ ] ...

### 效能檢查清單
- [ ] [檢查項]
- [ ] ...

## 📝 常見問題

**Q: [常見問題 1]?**  
A: [Skill 建議的答案]

**Q: [常見問題 2]?**  
A: [參考 template/ 或 references/]
```

### Step 4: 創建資產 (1-2 小時)

**必須的資產** (minimum):
```
templates/
├── minimal-example.go        # 最少實現 (copy-paste 直接用)
├── best-practice-example.go  # 包含 error-handling, logging
└── test-template.go          # 單元測試範本

checklists/
├── design-review.md          # Phase 1 檢查清單
└── code-review.md            # Phase 2 檢查清單

references/
├── best-practices.md         # "為什麼這樣做"
├── decision-tree.md          # 決策邏輯圖
└── FAQ.md                    # 常見問題
```

**例子** (templates/controller-template.go):

```go
// Controller template for backend-api-development skill
// 最少實現版本，複製後修改 TodoController 和相關邏輯

package controllers

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "your-project/app/services"
    "your-project/app/models"
)

type TodoController struct {
    TodoService services.TodoService
}

// NewTodoController 初始化
func NewTodoController(service services.TodoService) *TodoController {
    return &TodoController{
        TodoService: service,
    }
}

// GetTodoByID 單個查詢
// 決策點: 是否需要快取?
//   YES → 用 redis.Get + cache-aside pattern
//   NO → 直接查資料庫
func (c *TodoController) GetTodoByID(ctx *gin.Context) {
    id := ctx.Param("id")
    
    // 驗證 input
    if id == "" {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
        return
    }
    
    // 呼叫 service 層 (業務邏輯)
    todo, err := c.TodoService.GetByID(ctx, id)
    if err != nil {
        // 統一錯誤處理
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    // 成功回應
    ctx.JSON(http.StatusOK, gin.H{"data": todo})
}

// CreateTodo 新增
// 最佳實踐: 驗證 → Service → Response
func (c *TodoController) CreateTodo(ctx *gin.Context) {
    var req models.CreateTodoRequest
    
    // 驗證 request body
    if err := ctx.ShouldBindJSON(&req); err != nil {
        ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // 呼叫 service
    todo, err := c.TodoService.Create(ctx, &req)
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    // 201 Created (REST 最佳實踐)
    ctx.JSON(http.StatusCreated, gin.H{"data": todo})
}
```

### Step 5: 測試 & 驗收 (1 小時)

**驗收清單**:
```
□ SKILL.md 語法正確 (沒有 YAML 錯誤)
□ applyTo glob 模式符合預期
□ description 觸發短語清晰 (開發者能理解)
□ 5+ 開發者試用, 反饋 >80% "有幫助"
□ 所有範本可直接使用 (copy-paste)
□ 檢查清單項數 8-15 項 (太多/太少都不好)
□ 沒有過時的 API/工具參考
```

**試用反饋表單** (Google Form):
```
Skill 名稱: [自動帶]
試用日期: [自動帶]

1. 這個 Skill 對你有幫助嗎?
   ○ 很有幫助 (節省 >30% 時間)
   ○ 有幫助 (節省 15-30%)
   ○ 有一點幫助
   ○ 沒幫助

2. 哪些部分最有價值? (複選)
   ☑ 決策樹
   ☑ 檢查清單
   ☑ 範本程式碼
   ☑ 最佳實踐說明
   ☐ 其他

3. 改進建議? (自由填寫)

4. 會再用嗎? ○ YES ○ NO ○ 不確定
```

### Step 6: 上線與文檔 (30分)

**部署**:
1. 所有檔案推送到 `.github/skills/[skill-name]/`
2. 更新 `.github/skills/README.md` (新增入口連結)
3. 發送 Slack/Email 通知團隊

**文檔**:
- [ ] Skill 記錄在 [SKILL 導航表](../02-project-analysis/)
- [ ] 短 5 分鐘教學影片上線 (YouTube 或內部平台)
- [ ] 加入每週 Office Hours 推廣 (30分)

---

## 🧩 Skill 層疊設計

Skill 可以相互組合、巢狀使用，例如：

```
功能開發 Workflow
├─ 使用 backend-api-development Skill
│  ├─ 設計 API 端點
│  ├─ 實現 Controller + Service
│  └─ 內嵌 "快取決策樹" (來自 cache Skill)
│
├─ 使用 data-pipeline-airflow Skill (如果涉及資料轉換)
│  ├─ 設計 DAG
│  └─ 實現 Operator
│
└─ 使用 infrastructure-deployment Skill (如果涉及部署)
   ├─ 設計 Docker 映像
   └─ 部署到 K8s
```

---

## ⚙️ SKILL.md Frontmatter 詳解

### name
```yaml
name: backend-api-development
# 對應檔案夾名稱，必須一致
# 用 kebab-case (小寫 + 連字號)
```

### description ⭐⭐⭐
```yaml
description: "Use when: 開發 Go 後端 API、新增 Controllers、Models、Services；實作 JWT 認證、資料驗證；優化 GORM 查詢和 Redis 快取。適用於新功能 endpoint、資料層擴充、效能調優。"
# ⭐ 最重要! 決定何時自動載入
# 規則:
#   1. 須包含 "Use when:" 字首
#   2. 至少 3 個觸發短語 (逗號分隔)
#   3. 要描述具體場景 ("API 開發" 優於 "開發")
#   4. 全句應包含":", 必須用雙引號 escape
```

### applyTo
```yaml
applyTo: "Taipei-City-Dashboard-BE/**"
# Glob 模式，決定對哪些檔案應用
# 例:
#   "**/*.go"               → 所有 Go 檔案
#   "Taipei-City-Dashboard-BE/**"  → BE 資料夾
#   "src/components/**"     → 組件資料夾
#   "**"                    → 所有檔案 (謹慎用!)
```

---

## 🐛 常見陷阱

### 陷阱 1: Frontmatter 語法錯誤
```yaml
❌ 錯誤 (未引號, unsafe yaml)
description: Use when: API design, error handling: best practices

✅ 正確 (全句引號)
description: "Use when: API design, error handling; best practices"
```

### 陷阱 2: applyTo 過於寬泛
```yaml
❌ applyTo: "**"     # 所有檔案都載入! 浪費 context
✅ applyTo: "Taipei-City-Dashboard-BE/**"  # 只在 BE 載入
```

### 陷阱 3: 決策樹過於複雜
```
❌ 20+ 決策點，樹深度 > 5 層 (太難理解)
✅ 5-10 決策點，樹深度 2-3 層
```

### 陷阱 4: 範本不可直接使用
```go
❌ // TODO: 填入你的邏輯  (開發者需要自己改)
✅ // 最小實現 (複製後改 function 名稱即可)
   type MyController struct { ... }
   func (c *MyController) GetItem(ctx *gin.Context) { ... }
```

### 陷阱 5: 檢查清單太多或太少
```
❌ 30+ 項檢查清單 (開發者會跳過)
✅ 8-12 項檢查清單 (適中, 平衡覆蓋)
```

---

## 📊 Skill 成熟度評估

| 等級 | 特徵 | 維護週期 | 適合階段 |
|-----|------|---------|---------|
| Beta (試用) | 基礎框架; 反饋不足 | 每週 | Phase 1 |
| Stable (穩定) | 經 10+ 開發者驗證; 反饋 >80% | 每月 | Phase 2 |
| Mature (成熟) | 經 >30 開發者驗證; 反饋 >90%; API 穩定 | 每季 | Phase 3 |
| Legacy (維護) | 被新 Skill 取代; 維護只修緊急 bug | 按需 | 歷史 |

---

## 📞 支援與反饋

### 如何反饋 Skill 改進?

1. **Quick Feedback** (1分) - Slack 頻道 #skill-feedback
2. **Formal Issue** (5分) - GitHub Discussions
3. **Office Hours** (30分) - 每週四 3PM (Zoom)
4. **Comprehensive Review** (半年一次) - Steering Committee

### 如何提議新 Skill?

1. 填寫 Skill 提案表單 (3分)
2. Tech Lead 評估優先級 (5分)
3. 社群投票 (可選)
4. 如優先級 P0, 納入下一季計畫

---

## 📎 附件

- [04-skill-creation-template.md](./04-skill-creation-template.md) - 快速檢查清單
- [backend-api-development SKILL.md 完整例子](../../../.github/skills/backend-api-development/SKILL.md)
- [VS Code Copilot Skill 官方文檔](https://code.visualstudio.com/docs/copilot/overview)
