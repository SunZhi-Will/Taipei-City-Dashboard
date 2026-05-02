# 食安儀表板改名與台北/雙北分流 / Rename and Split Food Safety Dashboards

## 2026-05-03 02:48

- objective:
  - 將食安儀表板名稱與分組語意對齊
  - 達成「台北只出現純台北」的側欄行為
  - 保留雙北版本供 metrotaipei 區塊使用

- files:
  - migrations/food_safety_components.sql
  - migrations/add_food_safety_components.sql
  - migrations/reset_food_safety_clean.sh

- summary:
  - 新增 `food_safety_taipei`（名稱：臺北食品安全），只掛 `taipei` 群組
  - 保留 `food_safety_tpe`（名稱：雙北食品安全），只掛 `metrotaipei` 群組
  - 更新 migration 與 clean reset 腳本，確保重建後分流邏輯一致
  - 針對現場資料進行一次性群組清理，移除 `food_safety_tpe` 的 `taipei` 綁定殘留

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `food_safety_components.sql`：
    - upsert `food_safety_taipei`（components: `taipei_imap_food + food_poisoning_*`）
    - upsert `food_safety_tpe`（保留雙北組件，含 `ntpc_food_factory`、`wholesale_pesticide_inspection`）
    - dashboard_groups 綁定改為：
      - `food_safety_taipei -> group 2 (taipei)`
      - `food_safety_tpe -> group 3 (metrotaipei)`
  - `add_food_safety_components.sql`：同步加入相同分流邏輯
  - `reset_food_safety_clean.sh`：清理名單加入 `food_safety_taipei`

- verification:
  - `SELECT d.index,d.name,array_agg(g.name) ...` 驗證 group 綁定：
    - `food_safety_taipei -> {taipei}`
    - `food_safety_tpe -> {metrotaipei}`
  - `GET /api/v1/dashboard/food_safety_taipei?city=taipei` -> HTTP 200
  - `GET /api/v1/dashboard/food_safety_tpe?city=metrotaipei` -> HTTP 200
  - `GET /api/v1/dashboard/` 分組結果：
    - `taipei = [map-layers-taipei, food_safety_taipei]`
    - `metrotaipei = [map-layers-metrotaipei, food_safety_tpe]`

- performance-impact:
  - 無直接效能影響
  - 僅調整 dashboard metadata 與群組綁定

- impact-risk:
  - 若外部連結仍引用 `food_safety_tpe&city=taipei`，該路徑語意不再建議使用
  - 需前端導覽或書籤改用 `food_safety_taipei&city=taipei`

- regression-test:
  - 重新整理側欄，確認「臺北儀表板」不再顯示「雙北食品安全」
  - 點擊兩個食安儀表板，確認台北版不含新北工廠/雙北農藥組件
  - 重跑 `reset_food_safety_clean.sh` 後再次驗證分組結果不回歸

- traceability:
  - 相關分析：台北區塊出現雙北資料，根因為 `dashboard_groups` 雙綁定
  - 相關修復：`user-added/log/2026-05-03/0240-one-step-clean-reset-food-safety.md`

- next-actions:
  - 可將前端預設路由改為 `food_safety_taipei`（city=taipei）以避免舊連結混淆