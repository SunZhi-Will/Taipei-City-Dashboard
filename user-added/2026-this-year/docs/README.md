# 2026 文件中心 (Docs)

最後更新: 2026-04-14
維護者: Sun + GitHub Copilot (GPT-5.3-Codex)

## 1. 目標

本資料夾用於集中管理你在 2026 年對 Taipei-City-Dashboard 專案的所有文件，包含:
- 專案完整分析
- 已做功能盤點
- 分支整併與風險評估
- 路線圖、任務、KPI
- 歷史報告歸檔

## 2. 文件分類

### 01-overview
- 文件入口、目錄規範、閱讀順序

### 02-project-analysis
- 專案完整分析 (架構、資料流、風險、機會、優先級)

### 03-features
- 你已完成或規劃中的功能清單、狀態、依賴、驗收基準

### 04-roadmap
- 里程碑、任務拆解、KPI、風險與緩解策略

### 05-archives
- 歷史分析報告與原始紀錄

### 06-dev-guides
- **新增 (2026-04-14)** 開發環境快速開始、故障排查、環境設定參考手冊

## 3. 建議閱讀順序
1. `07-agent-skills/README.md` (2分) - Agent/Skill 總覽
2. `07-agent-skills/01-pm-executive-summary.md` (5分) - PM 決策版
3. `07-agent-skills/02-organizational-impact.md` (8分) - 官方/組織視角
4. `07-agent-skills/03-technical-reference.md` (15分) - 技術實作指南
5. `07-agent-skills/04-skill-creation-template.md` (5分) - 快速建立模板
6. `06-dev-guides/f5-quick-deployment.md` - 開發環境快速啟動
7. `03-features/feature-inventory-2026.md`
8. `04-roadmap/roadmap-and-kpi.md`
9. `02-project-analysis/complete-project-analysis.md`
10. `05-archives/*`

## 4. 文件維護規則

1. 新增文件前，先確認是否可歸入既有分類。
2. 檔名格式建議: `YYYY-MM-DD_topic.md` 或 `subject-summary.md`。
3. 每份文件前 20 行需包含:
   - 日期
   - 目的
   - 依據來源
   - 輸出結論
4. 若是決策文件，務必附:
   - 風險
   - KPI
   - 下一步責任人與期限

## 5. 快速索引

- 專案完整分析: `02-project-analysis/complete-project-analysis.md`
- 功能盤點: `03-features/feature-inventory-2026.md`
- 路線圖與 KPI: `04-roadmap/roadmap-and-kpi.md`
- 歷史報告: `05-archives/2026-04-14_hackathon_update_analysis.md`
- 深層比對: `05-archives/2026-04-14_deep_merge_comparison.md`

## 6. 07-agent-skills 新增說明

- **Agent & Skill 完整指南** 已建於 `07-agent-skills/`
- 內容涵蓋 PM 角度、官方組織角度、技術實作角度與快速模板
- 人讀文件在 `user-added/2026-this-year/docs/07-agent-skills/`
- 機器可讀 Skill 設定在 `.github/skills/agent-skill-authoring/SKILL.md`
