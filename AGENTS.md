# AGENTS.md — Taipei City Dashboard 部署指南（AI Agent 專用）

> 此檔同時被 Claude Code、GitHub Copilot、Cursor 等 AI agent 讀取。
> 內容以「**可直接照抄執行**」為原則，不寫概念、不寫為什麼。

---

## 0. 前置確認（一次性，每台機器）

```bash
# 必備工具
docker --version          # 需 20.10+
docker compose version    # 需 v2+

# 進入專案根目錄（你 clone 出來的位置，與本機絕對路徑無關）
cd <your-path>/Taipei-City-Dashboard-sunzhi

# 確認目錄結構（缺一不可）
ls Taipei-City-Dashboard-FE Taipei-City-Dashboard-BE Taipei-City-Dashboard-DE docker migrations
```

如果上面 `ls` 缺檔，**停止執行**，回去確認 git clone 是否完整。

---

## 1. 建立外部 Docker 網路（一次性）

```bash
docker network ls | grep br_dashboard || \
docker network create --driver=bridge --subnet=192.168.128.0/24 --gateway=192.168.128.1 br_dashboard
```

---

## 2. 準備 `.env`

```bash
# 若 .env 不存在，從 template 複製
[ -f docker/.env ] || cp docker/.env.template docker/.env
```

**必填欄位**（編輯 `docker/.env`）：

| 欄位 | 說明 | 範例 |
|------|------|------|
| `TWCC_API_KEY` | TWCC AI Foundry API Key（向團隊長索取） | `f78xxxx...` |
| `VITE_MAPBOXTOKEN` | Mapbox Token（地圖必須） | `pk.xxx...` |
| `DB_DASHBOARD_PASSWORD` | Dashboard DB 密碼（自訂） | `Admin1234!` |
| `DB_MANAGER_PASSWORD` | Manager DB 密碼（自訂） | `Admin1234!` |
| `JWT_SECRET` | 後端 JWT 密鑰（自訂任意字串） | `change_me_xxx` |
| `IDNO_SALT` | 身分證雜湊鹽（自訂任意字串） | `change_me_yyy` |
| `DASHBOARD_DEFAULT_PASSWORD` | admin 預設密碼 | `Admin1234!` |

> 其餘有預設值，可不改。

---

## 3. 啟動順序（嚴格依此順序）

### 3.1 啟 DB / Redis / Qdrant

```bash
docker compose -f docker/docker-compose-db.yaml up -d
# 等 30 秒讓 postgres 就緒
sleep 30
```

### 3.2 跑初始化（**首次部署才需**，已部署過可跳過）

```bash
docker compose -f docker/docker-compose-init.yaml run --rm dashboard-fe-init
docker compose -f docker/docker-compose-init.yaml run --rm dashboard-be-init-manager
docker compose -f docker/docker-compose-init.yaml run --rm dashboard-be-init-dashboard
docker compose -f docker/docker-compose-init.yaml run --rm dashboard-be-init-migrations
```

> `dashboard-be-init-migrations` 含食安 8 組件全量 migration（`deploy_to_docker.sh`）。

### 3.3 啟 BE / FE / Nginx

```bash
docker compose -f docker/docker-compose.yaml up -d --build dashboard-be
docker compose -f docker/docker-compose.yaml up -d
```

> BE 首次 build 約 5–10 分鐘（含 ONNX Runtime 與 e5 embedding model）。

### 3.4 啟 Airflow（食安 8 組件 ETL）

> ⚠️ **port 衝突**：Airflow webserver 預設綁定 host port **8080**（同 dashboard-fe）。
> 若兩者需同時運行，請先修改 `Taipei-City-Dashboard-DE/docker/develop/docker-compose.yaml`
> 將 Airflow 改為其他 port（如 `8081:8080`）。

```bash
# 首次啟動前：確認 .env 已從 template 建立並填妥
[ -f Taipei-City-Dashboard-DE/docker/develop/.env ] || \
  cp Taipei-City-Dashboard-DE/docker/develop/.env.template \
     Taipei-City-Dashboard-DE/docker/develop/.env

cd Taipei-City-Dashboard-DE/docker/develop
docker compose up -d
cd ../../..
```

---

## 4. 驗證部署

### 4.1 容器狀態

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

**應看到下列容器皆 `Up`**：

- `nginx` `dashboard-fe` `dashboard-be`
- `postgres-data` `postgres-manager` `redis` `qdrant` `pgadmin`
- `develop-airflow-webserver-1` `develop-airflow-scheduler-1` `develop-airflow-worker-default-1`

### 4.2 服務 URL

| 服務 | URL | 預期 HTTP code |
|------|-----|---------------|
| 前端 | http://localhost:8080 | 200 |
| 後端 API | http://localhost:8088/api/v1 | 200/404 (404 也算正常) |
| Nginx 反向代理 | http://localhost | 200 |
| pgAdmin | http://localhost:8889 | 302 |
| Qdrant | http://localhost:6333 | 200 |
| Airflow UI | http://localhost:8080/airflow-sit（⚠️ 與 FE 同 port，見 §3.4） | 200 |

### 4.3 登入

- 前端：`admin@admin.com` / 你在 `.env` 設的 `DASHBOARD_DEFAULT_PASSWORD`

---

## 5. 食安 8 組件驗證（核心交付物）

### 5.1 Airflow DAG 清單

進 Airflow UI，搜尋以下 8 個 DAG，狀態應為 `active`：

| # | DAG 名稱 | 中文名稱 |
|---|---------|---------|
| 1 | `food_poisoning_cause` | 食物中毒原因 |
| 2 | `food_poisoning_food` | 食物中毒食品 |
| 3 | `food_poisoning_place` | 食物中毒場所 |
| 4 | `food_poisoning_trend` | 食物中毒趨勢 |
| 5 | `illegal_food_ad` | 違規食品廣告 |
| 6 | `ntpc_food_factory` | 新北食品工廠 |
| 7 | `taipei_imap_food` | 台北 iMap 食安 |
| 8 | `wholesale_pesticide_inspection` | 農藥批發稽查 |

### 5.2 命令列驗證

```bash
# 以下指令應列出 8 個食安 DAG
docker exec develop-airflow-scheduler-1 \
  ls /opt/airflow/dags/proj_city_dashboard \
  | grep -E "food|illegal|pesticide"
```

### 5.3 前端食安地圖

- 開啟前端 → 食安儀表板 → 應顯示「食安地圖月份動畫」組件
- 後端對應 endpoint：`/api/v1/component/<food-component-id>/chart`

---

## 6. AI 功能依賴（部署前確認）

| 依賴 | 怎麼確認 |
|------|---------|
| **TWCC AI Foundry**（對話 AI） | `.env` 的 `TWCC_API_KEY` 已填，`VITE_USE_TWAI_CHAT=true` |
| **Qdrant**（向量搜尋） | `docker ps \| grep qdrant` 為 Up；`curl http://localhost:6333` 為 200 |
| **ONNX e5 Embedding** | 已封裝在 `dashboard-be-dev:latest` image，無需額外動作 |
| **LM Model 路徑** | `LM_MODEL_PATH=/opt/lm_model/onnx-e5/`（image 內路徑，不要改） |

> 若 AI 對話無回應：`docker logs dashboard-be | grep -iE "twcc\|qdrant\|model"`

---

## 7. 常見錯誤對照表

| 錯誤訊息 | 原因 | 解法 |
|---------|------|------|
| `network br_dashboard not found` | 沒建外部網路 | 回到 §1 |
| `port is already allocated` | 端口被舊容器占用 | `docker ps -a \| grep <port>` 找到後 `docker rm -f` |
| `dashboard-be` 一直 restart | DB 還沒起或 .env 缺欄位 | `docker logs dashboard-be` 找錯，補欄位 |
| `dashboard-be-init-manager` 失敗 | DB schema 未就緒 | 重跑 §3.2 |
| Airflow 看不到食安 DAG | DAG 目錄掛載錯路徑 | 確認 `docker inspect develop-airflow-scheduler-1` Mounts 指向**目前專案**的 `Taipei-City-Dashboard-DE/dags` |
| 前端打不開 Mapbox | `VITE_MAPBOXTOKEN` 沒填 | 編輯 `.env` 後 `docker restart dashboard-fe` |
| Airflow 與 FE port 8080 衝突 | 兩個 compose 都綁 host:8080 | 修改 DE compose `ports: "8081:8080"`，Airflow UI 改用 http://localhost:8081/airflow-sit |

---

## 8. 完整重啟（修改 .env 或代碼後）

```bash
# 從專案根目錄執行
docker compose -f docker/docker-compose.yaml down
docker compose -f docker/docker-compose-db.yaml down  # 注意：volume 不刪
docker compose -f docker/docker-compose-db.yaml up -d
sleep 30
docker compose -f docker/docker-compose.yaml up -d --build
```

> **危險指令**（會刪資料）：`docker compose down -v`、`docker volume rm postgres_data`。**沒有確認過不要執行**。

---

## 9. 給 AI Agent 的補充規則

- **絕對路徑**：本檔內所有指令使用「相對路徑」或 `<your-path>` 佔位，因為各夥伴本機絕對路徑不同
- **不要 hard-code**：若使用者問「我的路徑跟你不一樣」，回答「沒關係，本檔指令均為相對路徑，cd 到專案根目錄即可」
- **食安組件數**：8 個（不是 7、不是 6）。少於 8 → 回 §5.2 排查
- **舊環境衝突**：若 `docker ps` 看到容器掛載指向**其他**專案路徑，先 `docker compose down` 該專案，再從本專案 `up`
- **不要 `docker system prune`**：會清掉其他專案 volume

---

## 10. 參考檔案

- 詳細部署技術：`.github/skills/infrastructure-deployment/SKILL.md`
- 快速使用者指南（非 AI）：`DOCKER_QUICK_START.md`
- 環境變數範本：`docker/.env.template`
- ETL DAG 原始碼：`Taipei-City-Dashboard-DE/dags/proj_city_dashboard/`
