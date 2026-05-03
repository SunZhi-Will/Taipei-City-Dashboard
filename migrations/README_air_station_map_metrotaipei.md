# 雙北空品測站地圖組件 `air_station_map_metrotaipei`

在 dashboardmanager 資料庫新增地圖組件，顯示雙北空氣品質監測站即時 AQI。點擊測站圓點彈出 AQI、主要污染物、PM2.5、發布時間等 6 項資訊。

- 設計文件：`docs/superpowers/specs/2026-04-23-air-station-map-design.md`
- 資料來源：既有表 `public.moenv_air_quality`（由 DAG `D050502` 每小時更新）
- **不動 DE 與 FE**，只在 BE 資料庫新增 4 筆 row

---

## ⚠️ 執行前請先看

**1. 先把你電腦上所有未 commit 的變更 `git commit` 掉**

這個 migration 不會動你的 repo 檔案，但萬一你想搭配 dashboard 調整或改 config，先 commit 會比較好 rollback。跑前請確認：

```
git status
```

沒有 `M` / `??` 檔案最安全。若有，先 commit 或 stash。

**2. 這份 migration 隨時可以還原**

我們有配套的 `rollback_air_station_map_metrotaipei.sql`，跑下去會：
- 把組件從所有 dashboards 陣列移除
- DELETE 4 張表內建立的 row

可重複執行、不會炸。撤銷指令：
```
docker exec -i -e PGPASSWORD=<你的密碼> postgres-manager psql -U postgres -d dashboardmanager < rollback_air_station_map_metrotaipei.sql
```

或直接跑 `rollback_air_station_map_metrotaipei.sql`（見最後一節）。

---

## 兩個資料庫的概念（重要）

本專案有**兩個 Postgres 容器**，需要看清楚哪個 script 對哪個 DB：

| 容器 | DB name | 裡面有什麼 | 港口 |
|---|---|---|---|
| `postgres-manager` | `dashboardmanager` | 組件設定（本次要改的 4 張表）| 5432（已對外曝 port，本機可直連）|
| `postgres-data` | `dashboard` | 實際資料表（`moenv_air_quality` 等）| 未對外曝 port，**要走 docker exec** |

本 migration **只改 postgres-manager / dashboardmanager**。`moenv_air_quality` 在另一個容器，只會被 BE Go code 在 runtime 執行 `query_chart` SQL 時讀取 — migration 本身不碰。

---

## 檔案清單

| 檔案 | 對哪個 DB | 用途 |
|---|---|---|
| `air_station_map_metrotaipei.sql` | dashboardmanager | 主 migration，建 4 筆 row |
| `rollback_air_station_map_metrotaipei.sql` | dashboardmanager | 反向移除 |
| `verify_air_station_map_metrotaipei.sql` | dashboardmanager | 驗證 4 筆 row |
| `attach_to_dashboard_air_station_map.sql` | dashboardmanager | 把組件掛到 dashboard |
| `verify_data_moenv_air_quality.sql` | **dashboard** | 確認 D050502 DAG 有資料（選用） |

所有 SQL 都用純 psql 命令，不依賴 shell 變數替換 — Windows cmd / PowerShell / Mac / Linux 都能跑。

---

## 前置條件

**1. Docker 容器 `postgres-manager` 已啟動**

```
docker ps --filter name=postgres-manager
```

應該看到 container running。

**2. `dashboard` 容器也在跑，且 `moenv_air_quality` 表有近期資料**（可選但建議）

```
docker exec -i postgres-data psql -U <user> -d dashboard < verify_data_moenv_air_quality.sql
```

`<user>` 用 `.env` 的 `DB_DASHBOARD_USER`（預設通常是 `postgres`）。預期看到：
- `total_rows` ≥ 10（雙北測站數量）
- `rows_in_last_2h` ≥ 1（代表 DAG 這兩小時跑過）

若 0 筆 → 到 Airflow 手動觸發 `D050502` DAG，或等下一次排程（每小時第 20 分）。

---

## 執行步驟（3 個指令完成）

以下命令兩種寫法（擇一）：
- **A. 透過 Docker exec**（推薦給 Windows 夥伴，不用裝 psql）
- **B. 本機 psql 直連**（需自己裝 psql client；host 已有 5432 port）

### Step 1：跑 migration

**A. Docker 版**
```
docker exec -i postgres-manager psql -U <user> -d dashboardmanager < air_station_map_metrotaipei.sql
```

**B. 本機 psql 版**
```
psql -h localhost -p 5432 -U <user> -d dashboardmanager -f air_station_map_metrotaipei.sql
```

`<user>` 用 `.env` 的 `DB_MANAGER_USER`（預設 `postgres`）。執行時會問密碼（或設 `PGPASSWORD` 環境變數）。

預期輸出：
```
BEGIN
NOTICE:  使用 component id=<N>, map id=<M>
NOTICE:  ✅ air_station_map_metrotaipei 4 筆 row 建立完成
COMMIT
```

### Step 2：驗證

**A. Docker 版**
```
docker exec -i postgres-manager psql -U <user> -d dashboardmanager < verify_air_station_map_metrotaipei.sql
```

**B. 本機 psql 版**
```
psql -h localhost -p 5432 -U <user> -d dashboardmanager -f verify_air_station_map_metrotaipei.sql
```

預期 4 項檢查全部過：
1. 4 張表各 1 筆 row
2. 組件 id + map id 查得到
3. `paint` 與 `property` 欄位型別為 `jsonb`（不是 `text`！）
4. `query_chart` SQL 正確綁定 `city=metrotaipei`、`map_config_ids={M}`

### Step 3：把組件掛到 dashboard

預設目標：`map-layers-metrotaipei`（dashboardmanager-demo.sql 既有的雙北圖層 dashboard）。

要掛別的 dashboard，先編輯 `attach_to_dashboard_air_station_map.sql`，把：
```
\set target_dashboard '''map-layers-metrotaipei'''
```
改成你要的 dashboard index（引號保持三個單引號）。

**A. Docker 版**
```
docker exec -i postgres-manager psql -U <user> -d dashboardmanager < attach_to_dashboard_air_station_map.sql
```

**B. 本機 psql 版**
```
psql -h localhost -p 5432 -U <user> -d dashboardmanager -f attach_to_dashboard_air_station_map.sql
```

可重複執行（idempotent，已掛過會顯示「已包含，跳過」）。

### Step 4：瀏覽器驗收

重新整理 FE dashboard 頁面（預設 `http://localhost:8081`），預期看到：
- 雙北地圖上約 10-15 個測站圓點
- 圓點顏色按 AQI 分佈（大部分綠 / 黃，偶爾橘）
- 點擊圓點彈窗顯示 6 欄：測站名稱、AQI、空氣品質狀態、主要污染物、PM2.5、發布時間

---

## Rollback（反向移除）

**A. Docker 版**
```
docker exec -i postgres-manager psql -U <user> -d dashboardmanager < rollback_air_station_map_metrotaipei.sql
```

**B. 本機 psql 版**
```
psql -h localhost -p 5432 -U <user> -d dashboardmanager -f rollback_air_station_map_metrotaipei.sql
```

會做：從所有 dashboards.components 陣列移除此組件、DELETE 4 張表內的對應 row。可重複執行。

---

## 疑難排解

| 現象 | 原因 | 解法 |
|---|---|---|
| 地圖沒有任何點 | `moenv_air_quality` 空表或 DAG 沒跑 | 跑 `verify_data_moenv_air_quality.sql` 確認資料 |
| 所有點都綠色 | `aqi` 欄是 NULL 或 paint JSON 錯 | 檢查 `SELECT pg_typeof(paint) FROM component_maps WHERE index = 'air_station_map_metrotaipei';` 應為 `jsonb` |
| Popup 只顯示英文 key、沒中文 | `property` 寫成字串而非 JSONB | 同上，檢查 `property` 型別 |
| 點位在太平洋 | 座標系錯 | 跑 `verify_data_moenv_air_quality.sql` 第 3 項，SRID 應為 4326 |
| Migration 成功但 FE 看不到 | dashboard.components 沒更新 | 跑 Step 3 |
| `relation "moenv_air_quality" does not exist` | 跑在錯的 DB | 那支表在 `dashboard` DB，不在 `dashboardmanager`；BE runtime 才會讀它，migration 本身不會 |
| `could not connect to server` | port 或容器沒起 | `docker ps` 確認 postgres-manager running；本機 psql 要用 `-h localhost -p 5432` |
| `psql: command not found` (Windows) | 沒裝 psql client | 用 Docker 版（A 欄命令），不用裝 |

---

## 如果要修改

修改後請一起更新 `docs/superpowers/specs/2026-04-23-air-station-map-design.md`：

- 改 popup 欄位 → `air_station_map_metrotaipei.sql` 裡的 `property` JSON，spec §3.3
- 改 AQI 色階 → `paint` step expression 與 `component_charts.color`，spec §3.2
- 改測站篩選（例如加某區）→ `query_charts.query_chart` SQL
