# Agent & Skill 設定完整指南

**最後更新**: 2026-04-14  
**維護者**: PM Team + Technical Lead  
**狀態**: 🔴 新增（首次文檔化）

---

## 📑 文件導航

本資料夾包含 4 份核心文件，針對不同角色：

| # | 文件 | 對象 | 時長 | 用途 |
|----|------|------|------|------|
| 1 | **01-pm-executive-summary.md** | 主管/PM | 5分 | 業務價值、優先級、投資回報 |
| 2 | **02-organizational-impact.md** | 組織高層 | 8分 | 組織效益、風險、可交付物、成本 |
| 3 | **03-technical-reference.md** | 開發者 | 15分 | 技術實現、範例、最佳實踐 |
| 4 | **04-skill-creation-template.md** | 開發者 | 5分 | 快速檢查清單、範本程式碼 |

---

## 🎯 一覽表

### 什麼是 Agent Skill？
**定義**: VS Code Copilot 的專業化工作流程模組，包含：
- 特定領域知識與決策邏輯
- 可複用的步驟集合與最佳實踐  
- 關聯資產（範本、腳本、文件）
- 自動觸發條件（檔案模式 `applyTo`）

**效益**:
- ✅ 開發速度 ↑ 25-40% (自動決策、檢查清單)
- ✅ 程式碼品質 ↑ (一致性、型別安全、測試覆蓋)
- ✅ 上手時間 ↓ (新人用 skill 代替人工教學)
- ✅ 知識沈澱 (最佳實踐轉為可執行 workflow)

---

## 🚀 快速開始

### 給 PM
👉 先讀 **01-pm-executive-summary.md** (5分)  
了解優先級、ROI、里程碑

### 給組織高層  
👉 先讀 **02-organizational-impact.md** (8分)  
了解成本、風險、可交付物、組織效益

### 給開發者
👉 先讀 **03-technical-reference.md** (15分)  
了解怎麼寫 skill、範例、決策樹  
👉 再用 **04-skill-creation-template.md** (快速檢查清單)  
快速建立新 skill

---

## 📊 當前狀態

### 現有 Skill 清單 (已在 .github/skills 中)
```
✅ backend-api-development          (Go, API 設計)
✅ frontend-component-development   (Vue 3, UI 組件)
✅ data-pipeline-airflow            (Airflow DAG, ETL)
✅ geo-visualization                (地圖, Deck.gl)
✅ data-theme-integration           (新資料主題)
✅ ai-feature-development           (LLM, 向量搜尋)
✅ infrastructure-deployment        (Docker, K8s)
✅ component-integration-fullstack  (端對端發佈)
```

### 建議新增 Skill (後續迭代)
- `testing-strategy` - 單元測試、集成測試、E2E 最佳實踐
- `performance-optimization` - 評測、快取策略、優化決策
- `documentation-standards` - API 文檔、代碼註解、圖表標準
- `security-hardening` - 認證、授權、威脅模型

---

## 🔗 相關連結

- **Copilot 官方文檔**: [Skills Reference](https://code.visualstudio.com/docs/copilot/overview)
- **專案 Skill 目錄**: `/.github/skills/`
- **使用者提示詞**: `~/.vscode/extensions/github.copilot-chat-X.X.X/assets/prompts/skills/`
- **本專案分析**: `../02-project-analysis/complete-project-analysis.md`
- **專案路線圖**: `../04-roadmap/roadmap-and-kpi.md`

---

## ❓ 常見問題

**Q: 何時應該建立新 Skill？**  
A: 當該工作流程適用於 10+ 個相似場景、需要 5+ 個決策點、涉及 3+ 個檔案類型時。  
否則用指令或 Prompt 即可。

**Q: Skill 與 Instruction 有何不同？**  
A: Instruction 是全域規則 (常駐); Skill 是用戶選擇的工作流程 (可選)。

**Q: 一個 Skill 最多能用多久？**  
A: 建議每 3-6 個月檢查一次，更新最佳實踐、API 變更、新工具整合。

---

## 📝 維護規則

1. **文件更新**: 每月檢查一次新增 Skill 或工具變更
2. **內容驗證**: 每個 Skill 每季進行至少一次驗收測試
3. **版本管理**: 在 git 上追蹤所有變更，記錄 why
4. **反饋迴圈**: 收集開發者使用反饋，每季改進一個 Skill

---

## 📚 下一步

1. **立即** 👉 PM/決策者: 讀 01-pm-executive-summary.md
2. **本週** 👉 組織高層: 讀 02-organizational-impact.md
3. **本月** 👉 開發者: 讀 03-technical-reference.md, 用 04-skill-creation-template.md 建立新 skill
4. **持續** 👉 收集反饋，迭代改進
