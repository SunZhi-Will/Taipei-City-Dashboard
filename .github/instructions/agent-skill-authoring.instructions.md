---
applyTo: ".github/**"
description: "Use when: 新增或修改 Copilot Skill/Instruction/Agent 設定；希望 Copilot 真正讀到配置；需要同步 .github 與 user-added 文件入口。"
---

# Agent Skill Authoring Instructions

## Scope

本指示只適用於專案內 Copilot 客製化設定相關工作：
- `.github/skills/**`
- `.github/instructions/**`
- `.github/agents/**`
- `.github/prompts/**`

## Required Rules

1. 若需求是「讓 Copilot 讀得到」，設定必須落在 `.github/`，不能只放在 `user-added/`。
2. 新增 Skill 時，必須建立 `SKILL.md`，且 frontmatter 必須有 `name`、`description`、`applyTo`。
3. `description` 必須使用 `Use when:` 並包含明確觸發語句。
4. `applyTo` 必須盡量精準，避免預設使用 `**`。
5. 新增/修改 Skill 後，必須同步更新 `.github/skills/README.md` 的入口導航。
6. 若使用者要求文件化，需同步更新 `user-added/2026-this-year/docs/` 的入口與報告。
7. 預設不可修改官方文件（如 `.github/CONTRIBUTING.md`、根目錄 `README.md`）；除非使用者明確要求。

## Edit Boundary

- 允許修改:
	- `.github/skills/**`
	- `.github/instructions/**`
	- `user-added/2026-this-year/docs/**`
- 預設禁止修改:
	- `.github/CONTRIBUTING.md`
	- `README.md`
	- `.github/workflows/**`
	- 任何未被需求明確指派的官方檔案

## Validation Checklist

- [ ] frontmatter YAML 語法正確
- [ ] `name` 與資料夾名稱一致
- [ ] `description` 可被搜尋語句命中
- [ ] `applyTo` 不過寬
- [ ] `.github/skills/README.md` 已同步
- [ ] 若有文件需求，`user-added/2026-this-year/docs/` 已同步

## Anti-Patterns

- 只新增 `user-added` 文件，未新增 `.github` 設定。
- frontmatter 少欄位或欄位拼字錯誤。
- `description` 太抽象，缺少可觸發的關鍵語句。
- `applyTo: "**"` 濫用，造成上下文負擔。
- 未經同意修改官方文件（尤其 `.github/CONTRIBUTING.md`）。
