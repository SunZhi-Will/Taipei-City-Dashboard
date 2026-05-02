---
applyTo: "**"
description: "Use when: 任何程式碼或設定修正；每次修改後都要留下可稽核的變更紀錄，讓使用者可以快速確認。"
---

# Change Log Policy

## Scope

本規範適用於整個 repository 的所有修正工作（程式碼、設定、文件）。

## Required Rules

1. 每次完成修正後，必須在 `user-added/log/YYYY-MM-DD/` 新增一個 `HHmm-標題.md` 的紀錄檔。
2. 每筆 log 必須至少包含：日期、時間、修改檔案、變更摘要、驗證結果、影響風險、可追溯資訊。
3. 若同一回合修改多個檔案，可合併成一筆，但需列出完整檔案清單。
4. 路徑格式必須可辨識日期時間與主題，例如：`user-added/log/2026-04-17/1028-ai-stability-fix.md`。
5. 每筆 log 必須有中英文雙語標題，格式為「中文標題 / English Title」。
6. 每筆 log 必須標記 change type，僅能使用：`Added`、`Changed`、`Fixed`、`Removed`、`Security`。
7. 驗證段落需包含具體檢查方式（指令、檔案檢查或診斷結果），不可僅寫「已驗證」。
8. 對於技術修正，應補齊技術細節、性能影響、回歸測試建議等深度欄位，讓 log 本身可獨立作為技術文件。

## Preferred Filename Format

```md
user-added/log/YYYY-MM-DD/HHmm-title.md
```

## Preferred Entry Format

```md
# 中文標題 / English Title

## YYYY-MM-DD HH:mm

- objective:
  - 本次修正要解決的問題

- files:
  - path/to/fileA
  - path/to/fileB
- summary:
  - 說明本次做了什麼
  - 說明為何要這樣改
- change-type:
  - Added | Changed | Fixed | Removed | Security
- technical-details: (若涉及技術修正，補齊此欄)
  - 技術實現細節
  - 關鍵程式碼或配置變更
  - 演算法/流程調整
- verification:
  - 說明已執行的檢查或測試（附指令或檢查依據）
- performance-impact: (若涉及效能調整)
  - 預期改進或衝擊
  - 量化指標（如適用）
- impact-risk:
  - 說明影響範圍與已知風險
  - 邊界情況與降級策略
- regression-test: (建議進行的回歸驗證)
  - 測試項目清單
  - 驗證解析度/環境
- traceability:
  - 相關 log / ticket / PR / commit（若無則寫 N/A）
- next-actions:
  - 後續待辦與優先級（若無則寫 N/A）
```

## Validation Checklist

- [ ] 本次修正已新增 `user-added/log/YYYY-MM-DD/HHmm-標題.md`
- [ ] 日期、時間、檔案、摘要、驗證、風險、traceability 七要素完整
- [ ] change-type 使用標準分類（Added/Changed/Fixed/Removed/Security）
- [ ] 路徑符合 `user-added/log/YYYY-MM-DD/HHmm-title.md`
- [ ] 標題符合「中文 / English」雙語格式
