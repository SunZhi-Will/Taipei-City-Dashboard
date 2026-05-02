# 變更紀錄：命名規則修正 / Change Log: Naming Policy Fix

## 2026-04-17 10:28

- objective / 目標:
  - 將 log 產生策略從單一檔案改為「每回合一檔」，提升變更審閱可讀性與追溯效率。

- files / 修改檔案:
  - .github/instructions/change-log-policy.instructions.md
  - .github/instructions/agent-skill-authoring.instructions.md
  - user-added/log/2026-04-17-0955-change-log-policy-init.md
  - user-added/log/2026-04-17-1015-ai-stability-fix-batch1.md
  - user-added/log/2026-04-17-1028-log-naming-policy-fix.md

- summary / 變更摘要:
  - 調整規範敘述為每次修正產生一個獨立檔案，避免歷史混寫在同一檔案造成審閱困難。
  - 同步更新 instruction checklist 與 required rules，讓規範與執行檢查口徑一致。
  - 將既有紀錄遷移為獨立命名檔案，保留原始時間序並提升可搜尋性。
  - 將稽核從「一份日誌追全局」改為「一筆修正對一筆紀錄」，降低漏項風險。

- change-type / 變更類型:
  - Changed

- verification / 驗證結果:
  - 已確認 user-added/log 由單一檔模式轉為多檔模式。
  - 已確認兩份 instruction 文字都包含新的命名與檢查規則。
  - 已確認舊紀錄內容被保留且沒有遺失主要資訊。

- impact-risk / 影響與風險:
  - 影響範圍：記錄維護流程、PR 審核流程、問題回溯流程。
  - 正向影響：加快「某次修正做了什麼」的定位速度。
  - 已知風險：若未嚴格遵循命名規則，仍可能出現混合格式檔名。

- traceability / 追溯資訊:
  - related-log: user-added/log/2026-04-17/1028-log-naming-policy-fix.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions / 後續行動:
  - P1: 以 checklist 方式在每回合結尾自動檢查路徑與命名規則。
