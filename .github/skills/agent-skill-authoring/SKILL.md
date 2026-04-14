---
name: agent-skill-authoring
description: "Use when: 新增或修改 Copilot Agent/Skill 設定；撰寫 SKILL.md、.instructions.md、.agent.md；需要可被 Copilot 真正讀取的專案級配置。適用於 AI 工作流標準化、技能治理、文檔與實作對齊。"
applyTo: ".github/**"
---

# Agent Skill Authoring Skill

## 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 需求釐清 | 確認要做 Skill / Instruction / Agent | 選型錯誤率 0 | P0 |
| M2: 配置落地 | 建立可被 Copilot 讀取的設定檔 | Frontmatter 驗證 100% 通過 | P0 |
| M3: 入口同步 | 更新 .github/skills/README.md 導航 | 新增項目可被團隊找到 | P1 |
| M4: 治理對齊 | 人讀文件與機器配置對齊 | 文檔與配置差異 < 5% | P1 |

---

## 工作流程

### Phase 1: 選型 (Skill vs Instruction vs Agent)

1. 先判斷用途
   - 長流程、可重複、含決策樹與資產 -> Skill
   - 全域規則、常駐約束 -> Instruction
   - 需要子代理隔離上下文、多階段工具限制 -> Agent

2. 定義作用域
   - 專案共用 -> 放在 .github/
   - 個人偏好 -> 放在使用者 prompts 目錄 (非 repo)

3. 邊界確認
   - 預設不修改官方文件 (例如 .github/CONTRIBUTING.md、README.md)
   - 若要改官方文件，必須先得到使用者明確授權

### Phase 2: 建立可讀配置

3. 建立目錄
   - .github/skills/<skill-name>/SKILL.md
   - 如需附檔，再加 templates/, checklists/, references/

4. 寫 frontmatter
   - name: 要與資料夾名稱一致
   - description: 要有 Use when 與具體觸發語句
   - applyTo: 不要預設用 **，要限定範圍

### Phase 3: 驗收與入口

5. 內容驗收
   - 流程是否可執行
   - 決策點是否清楚
   - 檢查清單是否可用

6. 入口同步
   - 更新 .github/skills/README.md
   - 若有人讀文件，再同步 user-added/2026-this-year/docs/

7. 安全收斂
   - 僅提交本次需求範圍內檔案
   - 不主動擴散到 workflows、部署設定、官方導覽文件

---

## 快速檢查清單

- [ ] SKILL.md 位於 .github/skills/<name>/
- [ ] frontmatter 三個欄位完整: name, description, applyTo
- [ ] description 有 Use when 與 3 個以上觸發語句
- [ ] applyTo 非過寬 (避免 **)
- [ ] .github/skills/README.md 已新增入口
- [ ] 需要給人看的報告已放到 user-added/2026-this-year/docs/
- [ ] 未經授權未修改官方文件 (CONTRIBUTING/README/workflows)

---

## 常見問題

Q: 為何放在 user-added/docs 的內容 Copilot 不會自動讀?
A: 那是人類文件區，不是 Copilot 設定載入區。Copilot 會優先從 .github 相關自訂檔案中發現配置。

Q: 還要保留 user-added/docs 嗎?
A: 要。它是 PM/官方/技術對齊用文檔；但真正觸發 Copilot 行為的是 .github 下的配置檔。

Q: applyTo 可以用 ** 嗎?
A: 除非這份 Skill 必須對所有檔案生效，否則不建議。範圍過大會浪費上下文與干擾判斷。

Q: 官方文件可以一起順手更新嗎?
A: 不可以。預設禁止。只有使用者明確要求時才可改，且應最小化變更。
