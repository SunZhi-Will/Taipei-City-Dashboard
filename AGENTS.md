# AGENTS.md — Taipei City Dashboard 部署指南（AI Agent 專用）

> 此檔同時被 Claude Code、GitHub Copilot、Cursor 自動讀取。
> 內容以「**可直接照抄執行**」為原則。
> 全部使用相對路徑，跟你的本機絕對路徑無關。

---

## 0. 重要事實（先讀）

1. **食安儀表板有 7 個 component**（不是 8）：
   - 4 個食物中毒系列（id 223-226，用 query_charts 的 hardcoded VALUES）
   - 3 個地圖類（食品工廠 / 衛生稽查 / 蔬果農藥，需要 postgres-data 灌資料表）
   - illegal_food_ad 的 UI 尚未完成（DAG 有但無 GeoJSON、無 component）
2. **動畫地圖 2 張**：`taipei_imap_food` 與 `wholesale_pesticide_inspection`
   有 `component_maps.property._animate=month, interval_ms=1500`
3. **路徑無關**：所有指令使用相對路徑，先 `cd` 到專案根即可
4. **語言**：所有回應、commit message、程式註解一律繁體中文

---

## 1. 前置（一次性）

```bash
cd <你的路徑>/Taipei-City-Dashboard-sunzhi   # 切到專案根

# 必備工具
docker --version          # 需 20.10+
docker compose version    # 需 v2+

# 確認子專案結構齊全
ls Taipei-City-Dashboard-FE Taipei-City-Dashboard-BE Taipei-City-Dashboard-DE \
   docker migrations db-sample-data
```

### 1.1 建外部 Docker 網路

```bash
docker network ls | grep br_dashboard || \
docker network create --driver=bridge --subnet=192.168.128.0/24 \
                      --gateway=192.168.128.1 br_dashboard
```

### 1.2 準備 .env

```bash
# 主 env（含 TWCC_API_KEY 等）
[ -f docker/.env ] || cp docker/.env.template docker/.env

# Airflow env（含 MOENV_API_KEY，repo 不放，跟團隊長拿）
[ ! -f Taipei-City-Dashboard-DE/docker/develop/.env ] && \
  echo "❗缺 Airflow .env — 請跟團隊長索取後放入這個路徑"
```

### 1.3 必要目錄

```bash
mkdir -p Taipei-City-Dashboard-DE/{logs,plugins,data}
mkdir -p Taipei-City-Dashboard-BE/tmp && chmod 777 Taipei-City-Dashboard-BE/tmp
```

---

## 2. 啟 DB / Redis / Qdrant

```bash
docker compose -f docker/docker-compose-db.yaml up -d
sleep 30   # 等 postgres 就緒
docker exec postgres-data pg_isready -U postgres   # 應回 accepting connections
```

---

## 3. 跑 init（**首次部署或拉到新 demo 才需要**）

```bash
docker compose -f docker/docker-compose-init.yaml up dashboard-fe-init
docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-manager
docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-dashboard
```

> `dashboard-be-init-manager` 自動載 `db-sample-data/dashboardmanager-demo.sql`，
> 含全部 16 個 component（食安 7 個都包了）。

---

## 4. 補食安資料表（地圖類 3 個 component 需要的 row-level data）

```bash
docker exec -i postgres-data psql -U postgres -d dashboard \
  < food_safety_3complete_data.sql
```

灌完應該看到 3 個表：
- `ntpc_food_factory` (1230 row)
- `taipei_imap_food` (13695 row)
- `wholesale_pesticide_inspection` (39254 row)

---

## 5. 啟 BE / FE / Nginx

```bash
docker compose -f docker/docker-compose.yaml \
               -f docker/docker-compose.override.yaml \
               up -d --build dashboard-be
docker compose -f docker/docker-compose.yaml \
               -f docker/docker-compose.override.yaml \
               up -d
```

> override 把 FE 端口改 8081 / Nginx 改 8082，避開 lineliff phpmyadmin 占用 8080。
> BE 首次 build 約 5-10 分鐘（含 ONNX runtime + e5 embedder）。

---

## 6. 啟 Airflow（含食安 8 個 ETL DAG）

```bash
cd Taipei-City-Dashboard-DE/docker/develop
docker compose -f docker-compose.yaml \
               -f docker-compose.override.yaml \
               up -d airflow-init airflow-webserver airflow-scheduler airflow-worker-default
cd ../../..
```

> override 把 Airflow 接到 `br_dashboard` 網路 + webserver port 8083 +
> 合併 worker queue（避免 monthly DAG 卡 heavy 隊列）。

---

## 7. 驗證

### 7.1 容器全 Up

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -v lineliff
```

應看到：`nginx dashboard-fe dashboard-be postgres-data postgres-manager redis qdrant pgadmin develop-airflow-{init,webserver,scheduler,worker-default}-1`

### 7.2 服務 URL

| 服務 | URL | 預期 |
|------|-----|------|
| 前端 | http://localhost:8081 | 200 |
| 後端 | http://localhost:8088 | 200 |
| Nginx | http://localhost:8082 | 200 |
| pgAdmin | http://localhost:8889 | 302 |
| Qdrant | http://localhost:6333 | 200 |
| Airflow | http://localhost:8083 | 302 |

### 7.3 食安儀表板有 7 個 component

```bash
docker exec postgres-manager psql -U postgres -d dashboardmanager \
  -c "SELECT array_length(components,1) AS cnt FROM dashboards WHERE index='food-safety-metrotaipei';"
# cnt = 7
```

### 7.4 動畫 property 寫入

```bash
docker exec postgres-manager psql -U postgres -d dashboardmanager \
  -c "SELECT index FROM component_maps WHERE property::text LIKE '%_animate%';"
# 應有 2 行：taipei_imap_food / wholesale_pesticide_inspection
```

### 7.5 Airflow 8 個食安 DAG 出現

```bash
docker exec develop-airflow-scheduler-1 \
  ls /opt/airflow/dags/proj_city_dashboard \
  | grep -E "food|illegal|pesticide"
# 應 8 行
```

### 7.6 瀏覽器目視

1. http://localhost:8081 → 登入 `admin@admin.com` / 你設的密碼
2. 進「**雙北食安儀表板**」應看到 7 張卡
3. 進「**地圖交叉比對**」開「食品稽查」或「蔬果農藥」圖層
4. 點位每 1.5 秒按月份切換，DonutChart 同步漸變

---

## 8. 補丁/增量更新（已部署過，要拉新版時）

```bash
git pull

# 如果 db-sample-data/dashboardmanager-demo.sql 變了：
docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-manager

# 如果只想增量補食安 4 個 → 7 個 component（不重 init 全 DB）：
docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
  < migrations/food_safety_metrotaipei.sql        # 4 食物中毒 idempotent
docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
  < migrations/food_safety_3complete_partial.sql  # 補上 3 個地圖

# 如果 FE/BE 程式碼變了：
docker restart dashboard-fe dashboard-be
```

---

## 9. 8 個食安 DAG vs 7 個 UI component 對應表

| # | DAG 名 | data 表 | UI 組件 | 顯示？ |
|---|--------|---------|---------|--------|
| 1 | food_poisoning_cause | (用 hardcoded) | `food_poisoning_cause_metrotaipei` | ✅ |
| 2 | food_poisoning_place | (用 hardcoded) | `food_poisoning_location_metrotaipei` | ✅ |
| 3 | food_poisoning_trend | (用 hardcoded) | `food_poisoning_trend_metrotaipei` | ✅ |
| 4 | food_poisoning_food | (用 hardcoded) | `food_poisoning_trend_by_cause_metrotaipei` | ✅ |
| 5 | ntpc_food_factory | ✅ 1230 row | `ntpc_food_factory` (symbol map) | ✅ |
| 6 | taipei_imap_food | ✅ 13695 row | `taipei_imap_food` (DonutChart + circle map + 月動畫) | ✅ |
| 7 | wholesale_pesticide_inspection | ✅ 39254 row | `wholesale_pesticide_inspection` (DonutChart + circle map + 月動畫) | ✅ |
| 8 | illegal_food_ad | (DAG 無資料表) | **未做 UI** | ❌ |

---

## 10. 常見錯誤對照

| 錯誤 | 解法 |
|------|------|
| `network br_dashboard not found` | 回 §1.1 建網路 |
| `port 8080 already allocated` | override 已改 8081；確認用 `-f docker-compose.override.yaml` |
| `dashboard-be` exit 127 (vite not found) | 跑 §3 dashboard-fe-init |
| `dashboard-be` permission denied on tmp/main | `chmod 777 Taipei-City-Dashboard-BE/tmp` |
| Airflow init exit 1 | 確認 `Taipei-City-Dashboard-DE/docker/develop/.env` 存在；`docker logs develop-airflow-init-1` |
| Airflow `could not translate host name "postgres-manager"` | 確認 Airflow override 把 network 設為 `br_dashboard external: true` |
| 食安儀表板少於 7 個圖 | 跑 §3 init 或 §8 增量 partial |
| 動畫不會跑 | 確認 §7.4 _animate 寫入；瀏覽器要在「地圖交叉比對」頁，不是儀表板頁 |

---

## 11. 危險操作（必須先問人）

- `docker compose down -v`（刪 volume，會丟 DB 資料）
- `docker volume rm postgres_data postgres_manager_data qdrant_data`
- `docker system prune`（會清掉其他專案）
- `git push --force` / `git reset --hard`
- 改 `docker/.env` 的 secret 後 rebuild image（避免 secret 烙印）

---

## 12. 不確定時

- DAG / ETL 細節：`Taipei-City-Dashboard-DE/dags/proj_city_dashboard/<dag_name>/`
- BE 路由與 controller：`Taipei-City-Dashboard-BE/app/controllers/`
- FE 食安組件 chart 邏輯：`Taipei-City-Dashboard-FE/src/dashboardComponent/components/`
- 月動畫機制：`Taipei-City-Dashboard-FE/src/store/{mapStore,timeStore}.js`
- 部署 SKILL：`.github/skills/infrastructure-deployment/SKILL.md`
