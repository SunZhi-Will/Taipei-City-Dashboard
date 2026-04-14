# Skill 建立快速檢查清單與範本

**日期**: 2026-04-14  
**對象**: 開發者 (想快速新增 Skill)  
**用時**: 5 分鐘 (清單) + 30 分鐘 (實作)

---

## ⚡ 5 分鐘快速評估

### 我需要新建 Skill 嗎？

```
□ 這個工作流程適用於 10+ 個場景?
  ○ YES  ○ NO → 用 Prompt 代替

□ 每次都要 5+ 個決策點?
  ○ YES  ○ NO → 用 Instruction 代替

□ 涉及 3+ 個不同檔案類型或領域?
  ○ YES  ○ NO → 可能太簡單

□ 同一個錯誤被多人重複犯?
  ○ YES  ○ NO

□ 有明確的 "最佳實踐" 方式可沈澱?
  ○ YES  ○ NO

═══════════════════════════════════════
結論:
✅ 4+ 個 YES → 建立 Skill (值得!)
⚠️  2-3 個 YES → 先試試 Instruction
❌ <2 個 YES → 不需要 Skill
```

---

## 📋 檢查清單: 新建 Skill 步驟

### ✅ Pre-flight (30分)

- [ ] **收集知識**
  - [ ] 找 5+ 個 "好" 的程式碼範例
  - [ ] 找 3+ 個 "壞" 的反面範例
  - [ ] 列出 5-10 個常見決策點
  - [ ] 蒐集 3+ 個程式碼審查反饋

- [ ] **訪談**
  - [ ] 訪談 1 名資深工程師 (30分)
  - [ ] 問: "如何指導新人完成這個工作流程?"
  - [ ] 問: "最常犯的錯誤有哪些?"

### ✅ 架構設計 (1 小時)

- [ ] **SKILL.md 框架**
  - [ ] `name:` - 檔案夾名稱 (kebab-case)
  - [ ] `description:` - 包含 "Use when:" + 3 個觸發短語
  - [ ] `applyTo:` - 檔案 glob 模式
  - [ ] 目標與里程碑 (M1, M2, M3)
  - [ ] 3-4 個工作階段 (Phase)
  - [ ] 5-10 個決策點 (決策樹)
  - [ ] 1 個檢查清單

- [ ] **資產規劃**
  - [ ] templates/ - 3+ 個程式碼範本
  - [ ] checklists/ - 2+ 個檢查清單
  - [ ] references/ - 2+ 個參考文檔

### ✅ 編寫 (2-3 小時)

- [ ] **SKILL.md 本文**
  - [ ] 完整工作流程 (所有 Phase)
  - [ ] 決策樹 (清晰、易懂)
  - [ ] 常見問題 (FAQ)

- [ ] **程式碼範本** (必須可直接使用)
  - [ ] minimal-example.* (最小實現)
  - [ ] best-practice-example.* (包含最佳實踐)
  - [ ] test-template.* (測試範本)

- [ ] **檢查清單**
  - [ ] 設計審查清單 (Phase 1)
  - [ ] 程式碼審查清單 (Phase 2-3)
  - [ ] 每份清單 8-12 項

### ✅ 驗證 (1 小時)

- [ ] **語法檢查**
  - [ ] YAML frontmatter 無錯誤 (用 yamllint)
  - [ ] 所有範本可以執行或編譯
  - [ ] Markdown 連結有效

- [ ] **實用性測試**
  - [ ] 5+ 開發者試用 (30分)
  - [ ] 收集反饋 (Google Form)
  - [ ] 根據反饋調整 (copy-paste 是否方便?)

- [ ] **完整性檢查**
  - [ ] 沒有過時 API 參考
  - [ ] 決策樹沒有歧義
  - [ ] 檢查清單項數適中 (8-12)

### ✅ 上線 (30分)

- [ ] **檔案部署**
  - [ ] 推送至 `.github/skills/[skill-name]/`
  - [ ] 確認目錄結構正確

- [ ] **文檔更新**
  - [ ] 更新 `.github/skills/README.md` (新增導航連結)
  - [ ] 在本文檔 (07-agent-skills/README.md) 新增項目
  - [ ] Slack 通知團隊

---

## 🎨 範本: 最小 Skill 結構

```
.github/skills/
└── my-new-skill/
    ├── SKILL.md                    # ⭐ 核心文檔
    ├── templates/
    │   ├── minimal-example.go      # 最小實現
    │   ├── best-practice.go        # 包含最佳實踐
    │   └── test-template.go        # 測試
    ├── checklists/
    │   ├── design-review.md        # 設計階段
    │   └── code-review.md          # 程式碼審查
    └── references/
        ├── best-practices.md       # "為什麼這樣做"
        └── decision-tree.md        # 決策邏輯

⏱️ 時間規劃:
  - SKILL.md:        1.5 小時
  - templates/:      1 小時 (3 個檔案)
  - checklists/:     30 分鐘
  - references/:     30 分鐘
  - 試驗 + 反饋:     1 小時
  ─────────────────────────────
  總計:              4.5 小時
```

---

## 📄 SKILL.md 最小範本

```markdown
---
name: [skill-name-kebab-case]
description: "Use when: [場景1, 場景2, 場景3]"
applyTo: "[glob pattern]"
---

# [Skill 標題]

## 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|---------|
| M1 | 分析與設計 | 0 breaking changes | P0 |
| M2 | 核心實現 | 90% 測試覆蓋 | P0 |
| M3 | 驗收與發佈 | 程式碼審查通過 | P1 |

## 工作流程

### Phase 1: 分析與設計
```
1. 需求確認
   ├─ [子步驟 1.1]
   └─ [子步驟 1.2]

2. 設計檢查
   ├─ [子步驟 2.1]
   └─ [子步驟 2.2]
```

### Phase 2: 實現
```
3. [實現具體組件]
   ├─ [子步驟]
   └─ [子步驟]

4. 測試
   └─ [測試方式]
```

### Phase 3: 審查與發佈
```
5. 程式碼審查
   ├─ 見 checklists/code-review.md
   └─ [子步驟]

6. 發佈
   └─ [發佈流程]
```

## 決策樹

### 決策點 1: [選項名稱]
```
條件 A (常見場景)
├─ YES → [推薦方案 A] (理由: ...)
└─ NO  → [推薦方案 B] (理由: ...)
```

## 最佳實踐

- **[最佳實踐 1]**: [解釋 + 反範例]
- **[最佳實踐 2]**: [解釋 + 範例]

## 檢查清單

### 設計審查
- [ ] [項目 1]
- [ ] [項目 2]
- [ ] [項目 3]

### 程式碼審查
- [ ] [項目 1]
- [ ] [項目 2]
- [ ] [項目 3]

## 常見問題

**Q: [常見問題]?**  
A: [建議答案 + 參考資源]

**Q: [常見問題]?**  
A: [建議答案 + 參考資源]
```

---

## 💾 範本檔案

### templates/minimal-example.go

```go
// Minimal example for [skill-name]
// 這是最簡單的實現，複製後僅需改名稱

package your_package

// YourComponent 簡單實現
type YourComponent struct {
    Name string
}

// NewYourComponent 初始化
func NewYourComponent(name string) *YourComponent {
    return &YourComponent{Name: name}
}

// DoSomething 基本操作
func (c *YourComponent) DoSomething() error {
    // 實現邏輯
    return nil
}
```

### templates/test-template.go

```go
// Test template for [skill-name]

package your_package

import (
    "testing"
)

func TestYourComponent_DoSomething(t *testing.T) {
    comp := NewYourComponent("test")
    err := comp.DoSomething()
    
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

// 邊界情況: 空值輸入
func TestYourComponent_DoSomething_Empty(t *testing.T) {
    comp := NewYourComponent("")
    err := comp.DoSomething()
    
    if err == nil {
        t.Error("expected error for empty input, got nil")
    }
}
```

### checklists/design-review.md

```markdown
# [Skill] 設計審查清單

在開始實現前，請逐項檢查：

- [ ] 需求明確，無歧義
- [ ] 資料模型已經確認或已有 SQL
- [ ] API contract (request/response) 已定義
- [ ] 有無類似的已有實現? (可複用)
- [ ] 有無潛在的效能風險?
- [ ] 有無安全考慮 (input validation, auth)?
- [ ] 錯誤場景已考慮 (null checks, exceptions)?
- [ ] 是否需要快取? (如是，快取策略是什麼?)

## 簽核者

- [ ] Tech Lead 同意
- [ ] 相關領域 Owner 同意
```

### checklists/code-review.md

```markdown
# [Skill] 程式碼審查清單

PR 提交前，請確保以下項目均已完成：

### 功能完整性
- [ ] 所有需求都已實現
- [ ] 原有功能未被破壞 (backward compatible)
- [ ] 邊界情況都已處理 (null, empty, error)

### 程式碼品質
- [ ] 命名清晰、遵循團隊規范
- [ ] 無重複程式碼 (DRY)
- [ ] 複雜邏輯都有註解

### 測試
- [ ] 單元測試覆蓋 >90%
- [ ] 新增了必要的集成測試
- [ ] 手動測試通過

### 安全與效能
- [ ] 輸入驗證處理
- [ ] 無 SQL injection / XSS 風險
- [ ] 效能符合預期 (<X ms response time)
- [ ] 快取策略已考慮 (if applicable)

### 文檔
- [ ] 代碼有適當的 doc comments
- [ ] 新增/修改的 API 已更新文檔
- [ ] README 如需要已更新

## 審查者

- [ ] 至少 1 名 Tech Lead 審查通過
- [ ] 對應功能領域 Owner 審查通過
```

---

## 🚀 提交流程

### Step 1: 準備

```bash
# 1. 建立分支
git checkout -b feat/skill-my-new-skill

# 2. 創建目錄結構
mkdir -p .github/skills/my-new-skill/{templates,checklists,references}

# 3. 編寫檔案 (用上述範本)
```

### Step 2: 本地驗證

```bash
# 有效性檢查
yamllint .github/skills/my-new-skill/SKILL.md

# 檢查所有範本是否可執行
cd .github/skills/my-new-skill/templates/
go vet ./...  # 如是 Go 程式

# 檢查 Markdown 連結
markdownlint checklists/ references/
```

### Step 3: 試用反饋

```
1. 邀請 5+ 開發者試用 (Slack 通知)
2. 收集反饋 (Google Form link: [待補])
3. 根據反饋調整 (通常 1-2 輪)
```

### Step 4: 發佈

```bash
# Push to main (經 code review)
git add .github/skills/my-new-skill/
git commit -m "feat: add my-new-skill for [use case]"
git push origin feat/skill-my-new-skill

# Create PR, 經 Tech Lead + PM 批准，合併到 main
# 自動後續: GitHub Action 會通知團隊
```

### Step 5: 上線通告

```
發送 Slack 訊息:
─────────────────────────────
🎉 新 Skill 上線: [my-new-skill]

用途: [簡單說明]
觸發詞: "Use when: [短語]"
文檔: [連結到 07-agent-skills/]

試試看! 👉 [doc link]
問題或反饋? 留言或 Slack DM

#新-skill #copilot
─────────────────────────────
```

---

## ❓ 常見問題

### Q: Skill 多久要更新一次?
**A**: 
- **Beta**: 每週 (根據反饋快速迭代)
- **Stable**: 每月 (修 bug, 微調)
- **Mature**: 每季 (大改進)

### Q: 舊的 Skill 怎麼廢棄?
**A**: 
1. 在 SKILL.md 頂端加 `[DEPRECATED]` 標籤
2. 向團隊推薦新 Skill
3. 6 個月後刪除

### Q: 能否複用其他專案的 Skill?
**A**: 
是的! 
- 找到原始 Skill 的來源 (GitHub/內部 repo)
- 複製到本專案 `.github/skills/`
- 記錄出處 (在 references/ 中)
- 調整 `applyTo` 模式符合本專案結構

### Q: 新人如何快速學會用 Skill?
**A**: 
1. 看 30 秒動畫介紹 (YouTube)
2. 跟著 Skill 的 Phase 1 步驟走
3. 提問→PM/Tech Lead 回答 (Office hours)
4. 試試看!

---

## 📞 取得幫助

| 問題 | 聯絡 | 時間 |
|-----|------|------|
| 特定 Skill 問題 | Skill 作者 (在 SKILL.md 記錄) | 非同步 (Slack) |
| 快速幫助 | Office hours (每週四 3PM) | 同步 (Zoom) |
| 新 Skill 議題 | PM + TechLead | 每季檢查 |
| 反饋/建議 | GitHub Discussions | 流動 |

---

## 📎 快速連結

- **回到完整指南**: [README.md](./README.md)
- **技術細節**: [03-technical-reference.md](./03-technical-reference.md)
- **PM 報告**: [01-pm-executive-summary.md](./01-pm-executive-summary.md)
- **Copilot 官方文檔**: https://code.visualstudio.com/docs/copilot/overview
- **現有 Skill 目錄**: `/.github/skills/` (參考實作)
