# 文件地圖與分類規範

日期: 2026-04-14

## A. 資料夾結構

```text
2026-this-year/
  docs/
    README.md
    01-overview/
      document-map.md
    02-project-analysis/
      complete-project-analysis.md
    03-features/
      feature-inventory-2026.md
    04-roadmap/
      roadmap-and-kpi.md
    05-archives/
      2026-04-14_hackathon_update_analysis.md
      2026-04-14_deep_merge_comparison.md
    06-dev-guides/
      f5-quick-deployment.md
      docker-environment-reference.md
    07-agent-skills/                     ⭐ 新增
      README.md                          (目錄導航)
      01-pm-executive-summary.md         (PM 角度 5分)
      02-organizational-impact.md        (官方角度 8分)
      03-technical-reference.md          (技術參考 15分)
      04-skill-creation-template.md      (快速檢查清單 5分)
```

## B. 文件用途

1. `complete-project-analysis.md`
- 全專案視角: 架構、流程、現況、機會、風險

2. `feature-inventory-2026.md`
- 以功能為單位追蹤: 狀態、價值、依賴、驗收

3. `roadmap-and-kpi.md`
- PM 可執行計畫: P0/P1

4. `06-dev-guides/`
- **f5-quick-deployment.md**: 一鍵啟動環境、常見問題排查
- **docker-environment-reference.md**: 環境變數、埠位、容器依賴、設定場景

5. `07-agent-skills/` ⭐ **新增：AI Agent Skill 完整指南**
   - **README.md**: 目錄導航、4 份報告介紹、快速開始
   - **01-pm-executive-summary.md** (5分): PM 報告 - ROI、里程碑、成本效益
   - **02-organizational-impact.md** (8分): 官方視角 - 組織效益、風險、治理
   - **03-technical-reference.md** (15分): 技術指南 - 怎麼寫 Skill、決策樹、最佳實踐
   - **04-skill-creation-template.md** (5分): 快速檢查清單、範本程式碼、提交流程

6. `05-archives/*`
- 保留原始分析紀錄，避免資訊流失

## C. 文件生命週期

1. 草稿: 在對應分類先建立草稿
2. 審閱: 標註假設、風險、待確認事項
3. 發布: 補齊 KPI 與下一步
4. 歸檔: 已過時內容移至 `05-archives`

## D. 命名規則
4. 開發指南: `topic-guide.md` (例: f5-quick-deployment.md)

1. 分析類: `YYYY-MM-DD_topic_analysis.md`
2. 功能類: `feature-name_summary.md`
3. 計畫類: `roadmap-period.md`
