# 精簡 migration 並修復錯誤檔 / Migration Cleanup and BAT Fix

## 2026-05-03 02:42

- objective:
  - 清理 migrations 目錄中不必要與錯誤的檔案
  - 修正 run_all.bat 內容污染，避免 Windows 使用者執行失敗
  - 保留核心可重建流程與必要 rollback

- files:
  - migrations/run_all.bat
  - migrations/food_safety_tables.sql（刪除）
  - migrations/fix_food_safety_chart_data.sql（刪除）
  - migrations/fix_food_safety_display_bugs.sql（刪除）
  - migrations/rollback_fix_food_safety_chart_data.sql（刪除）
  - migrations/rollback_fix_food_safety_display_bugs.sql（刪除）

- summary:
  - 發現 `run_all.bat` 尾端誤混入 patch 文字與 bash 腳本內容（`*** Add File` / `#!/bin/bash`）
  - 已移除污染片段，恢復純 Windows bat 腳本
  - 移除已確認重複檔：`food_safety_tables.sql`（與 `food_safety_data.sql` 內容相同）
  - 移除一次性修補 SQL 與其 rollback（已由主 migration 邏輯覆蓋）

- change-type:
  - Fixed
  - Removed

- technical-details:
  - `run_all.bat` 保留到 `:error` 區塊結束，不再夾雜 shell 語法
  - 透過檔案雜湊確認 `food_safety_tables.sql` 與 `food_safety_data.sql` 完全一致
  - 精簡後保留的食安核心檔案為：
    - `add_food_safety_components.sql`
    - `add_food_safety_data_tables.sql`
    - `food_safety_components.sql`
    - `food_safety_data.sql`
    - `rollback_food_safety_components.sql`
    - `reset_food_safety_clean.sh`

- verification:
  - `perl -ne 'print $. . ":" . $_ if /Add File|^#\!\/bin\/bash/' migrations/run_all.bat` → 無輸出
  - `get_errors` 檢查 `migrations/run_all.bat` → No errors
  - `ls migrations | grep -E 'food_safety|run_all|fix_food_safety|rollback_fix_food_safety'` → 已無被刪除檔案

- performance-impact:
  - 無執行效能影響
  - 僅降低維護成本與誤用風險

- impact-risk:
  - 刪除的一次性修補 SQL 若未來需要追溯，需從 git 歷史還原
  - 已保留核心資料重建與 rollback 主線，不影響目前一鍵重建流程

- regression-test:
  - Windows 端可用 `run_all.bat` 進行語法冒煙測試
  - macOS 端以 `reset_food_safety_clean.sh` 持續驗證食安重建流程

- traceability:
  - 相關清理背景：`user-added/log/2026-05-03/0240-one-step-clean-reset-food-safety.md`
  - 相關重複檔確認：`user-added/log/2026-05-03/0155-replace-food-safety-components-sql.md`

- next-actions:
  - 可再把 migrations 依主題分資料夾（food_safety / map_layers / air_quality），降低後續維護複雜度