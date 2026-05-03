#!/usr/bin/env bash
# bootstrap.sh — 一條指令啟動 Taipei City Dashboard（食安儀表板）
#
# 用法：
#   bash bootstrap.sh
#
# 前置：先取得 docker/.env 與 Taipei-City-Dashboard-DE/docker/develop/.env（跟團隊長要）
#
# 平台：macOS / WSL2 / Linux 都跑得起來

set -e

YELLOW='\033[1;33m'; GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $*${NC}"; }
warn() { echo -e "${YELLOW}[!] $*${NC}"; }
err()  { echo -e "${RED}[✗] $*${NC}"; }

# ─── Step 0: 偵測平台 ──────────────────────────────────────────
case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then PLATFORM=wsl
    else PLATFORM=linux
    fi ;;
  *) PLATFORM=other ;;
esac
log "Platform: $PLATFORM"

# ─── Step 1: 工具檢查 ──────────────────────────────────────────
command -v docker >/dev/null 2>&1 || { err "docker 未安裝"; exit 1; }
docker compose version >/dev/null 2>&1 || { err "docker compose v2 未安裝"; exit 1; }
docker info >/dev/null 2>&1 || {
  err "Docker 未啟動（macOS 請先打開 Docker Desktop，等鯨魚變綠）"; exit 1;
}
log "Docker 正常"

# ─── Step 2: 確認專案目錄結構 ─────────────────────────────────
for dir in Taipei-City-Dashboard-FE Taipei-City-Dashboard-BE Taipei-City-Dashboard-DE \
           docker migrations db-sample-data; do
  [ -d "$dir" ] || { err "缺資料夾 $dir，是否在專案根目錄？"; exit 1; }
done
log "專案結構 OK"

# ─── Step 3: 檢查 .env ────────────────────────────────────────
if [ ! -f docker/.env ]; then
  warn "docker/.env 不存在，從 template 複製"
  cp docker/.env.template docker/.env
  err "請編輯 docker/.env 填上 TWCC_API_KEY / VITE_MAPBOXTOKEN（找團隊長拿）後重跑"
  exit 1
fi

if [ ! -f Taipei-City-Dashboard-DE/docker/develop/.env ]; then
  err "缺 Taipei-City-Dashboard-DE/docker/develop/.env（含 MOENV_API_KEY）"
  err "請跟團隊長索取後放入該位置再重跑"
  exit 1
fi
log ".env 都到位"

# ─── Step 4: Docker 網路 ──────────────────────────────────────
if ! docker network ls | grep -q br_dashboard; then
  log "建立 docker 網路 br_dashboard"
  docker network create --driver=bridge \
    --subnet=192.168.128.0/24 --gateway=192.168.128.1 br_dashboard
fi

# ─── Step 5: 必要目錄 + 權限 ─────────────────────────────────
mkdir -p Taipei-City-Dashboard-DE/{logs,plugins,data}
mkdir -p Taipei-City-Dashboard-BE/tmp
if [ "$PLATFORM" != "macos" ]; then
  chmod 777 Taipei-City-Dashboard-BE/tmp 2>/dev/null || true
fi
log "目錄與權限就緒"

# ─── Step 6: 啟 DB / Redis / Qdrant ───────────────────────────
log "啟 DB / Redis / Qdrant"
docker compose -f docker/docker-compose-db.yaml up -d

log "等 postgres 就緒..."
for i in $(seq 1 60); do
  if docker exec postgres-data pg_isready -U postgres >/dev/null 2>&1 && \
     docker exec postgres-manager pg_isready -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# ─── Step 7: 偵測首次部署 ────────────────────────────────────
NEEDS_INIT=true
if docker exec postgres-manager psql -U postgres -d dashboardmanager -tAc \
     "SELECT 1 FROM information_schema.tables WHERE table_name='dashboards'" 2>/dev/null \
   | grep -q 1; then
  NEEDS_INIT=false
fi

if $NEEDS_INIT; then
  log "首次部署：跑 init（FE npm ci / Manager DB / Dashboard DB）"
  docker compose -f docker/docker-compose-init.yaml up dashboard-fe-init
  docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-manager
  docker compose -f docker/docker-compose-init.yaml up dashboard-be-init-dashboard
else
  warn "DB 已初始化過，跳過 init（要強制重 init 改用：docker compose -f docker/docker-compose-init.yaml up）"
fi

# ─── Step 8: 補食安 partial migration（idempotent，重跑無害） ────
log "套用食安 SQL（4 食物中毒 + 3 地圖類）"
docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
  < migrations/food_safety_metrotaipei.sql >/dev/null
docker exec -i postgres-manager psql -U postgres -d dashboardmanager \
  < migrations/food_safety_3complete_partial.sql >/dev/null

# ─── Step 8.5: 食安資料表（永遠覆蓋，確保 100% 複製 sun 的本地狀態） ─────
#   food_safety_data.sql 含 DROP TABLE IF EXISTS，重跑安全
log "套用食安資料表（DROP + RECREATE 3 表，確保資料同步 sun 本地）"
docker exec -i postgres-data psql -U postgres -d dashboard \
  < db-sample-data/food_safety_data.sql >/dev/null
FOOD_ROWS=$(docker exec postgres-data psql -U postgres -d dashboard -tAc \
  "SELECT count(*) FROM public.taipei_imap_food" 2>/dev/null || echo 0)
log "食安資料就緒：taipei_imap_food = $FOOD_ROWS 行（預期 13695）"

# ─── Step 9: 偵測 port 8080 是否被占 ─────────────────────────
USE_OVERRIDE=""
PORT_FE=8080; PORT_NGINX=80

# 三層偵測，任一中即視為 busy
PORT_BUSY=false
docker ps --format '{{.Ports}}' 2>/dev/null \
  | grep -E "0\.0\.0\.0:8080->|:8080->" -q && PORT_BUSY=true
if ! $PORT_BUSY && command -v ss >/dev/null 2>&1; then
  ss -tuln 2>/dev/null | grep -q ":8080 " && PORT_BUSY=true
fi
if ! $PORT_BUSY && command -v lsof >/dev/null 2>&1; then
  lsof -nP -i :8080 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN && PORT_BUSY=true
fi

if $PORT_BUSY; then
  warn "port 8080 已被占用，套用 override (FE→8081, Nginx→8082)"
  USE_OVERRIDE="-f docker/docker-compose.override.yaml"
  PORT_FE=8081; PORT_NGINX=8082
fi

# ─── Step 10: 啟 BE / FE / Nginx ─────────────────────────────
log "build BE image（含 ONNX runtime + e5 embedder，首次約 5-15 分鐘）"
docker compose -f docker/docker-compose.yaml $USE_OVERRIDE up -d --build dashboard-be

log "啟 FE / Nginx"
docker compose -f docker/docker-compose.yaml $USE_OVERRIDE up -d

# ─── Step 11: 啟 Airflow ─────────────────────────────────────
log "啟 Airflow（init / webserver / scheduler / worker-default）"
(
  cd Taipei-City-Dashboard-DE/docker/develop
  docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d \
    airflow-init airflow-webserver airflow-scheduler airflow-worker-default
)

# ─── Step 12: 驗證 ───────────────────────────────────────────
echo ""
log "=== 驗證 ==="

CC=$(docker exec postgres-manager psql -U postgres -d dashboardmanager -tAc \
       "SELECT array_length(components,1) FROM dashboards WHERE index='food-safety-metrotaipei'" 2>/dev/null)
[ "$CC" = "7" ] && log "食安儀表板 component: $CC ✅" || warn "食安儀表板 component: $CC (預期 7)"

AC=$(docker exec postgres-manager psql -U postgres -d dashboardmanager -tAc \
       "SELECT count(*) FROM component_maps WHERE property::text LIKE '%_animate%'" 2>/dev/null)
[ "$AC" = "2" ] && log "_animate 動畫地圖: $AC ✅" || warn "_animate 動畫地圖: $AC (預期 2)"

DC=0
for tbl in ntpc_food_factory taipei_imap_food wholesale_pesticide_inspection; do
  CNT=$(docker exec postgres-data psql -U postgres -d dashboard -tAc "SELECT count(*) FROM $tbl" 2>/dev/null || echo 0)
  [ "${CNT:-0}" -gt 0 ] && DC=$((DC+1))
done
[ "$DC" = "3" ] && log "食安資料表（3 表）: 全部有資料 ✅" || warn "食安資料表只有 $DC/3 有資料"

# ─── Step 13: URL ─────────────────────────────────────────────
echo ""
log "🎉 部署完成"
echo ""
echo "  前端:    http://localhost:$PORT_FE"
echo "  後端:    http://localhost:8088"
echo "  Nginx:   http://localhost:$PORT_NGINX"
echo "  pgAdmin: http://localhost:8889"
echo "  Qdrant:  http://localhost:6333"
echo "  Airflow: http://localhost:8083"
echo ""
echo "  登入：admin@admin.com / 你在 docker/.env 設的 DASHBOARD_DEFAULT_PASSWORD"
echo ""
echo "  食安儀表板：登入後左側選「雙北食安儀表板」（7 張卡）"
echo "  動畫地圖：「地圖交叉比對」開食品稽查或農藥圖層，1.5s 月份輪播"
