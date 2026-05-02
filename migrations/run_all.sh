#!/usr/bin/env bash
# Mac / Linux 一鍵執行腳本
# 用法：
#   cd migrations/
#   chmod +x run_all.sh
#   ./run_all.sh

set -euo pipefail

# ====== 設定區 ======
CONTAINER="${CONTAINER:-postgres-manager}"
PG_USER="${PG_USER:-postgres}"
DATABASE="${DATABASE:-dashboardmanager}"
DASHBOARD_INDEX="${DASHBOARD_INDEX:-map-layers-metrotaipei}"

# 密碼（可選，未設會提示輸入）
if [ -z "${PGPASSWORD:-}" ]; then
  read -rsp "請輸入 $DATABASE 的 $PG_USER 密碼: " PGPASSWORD
  echo
  export PGPASSWORD
fi

run_sql() {
  local file="$1"
  local label="$2"
  echo
  echo "===== $label ====="
  docker exec -i -e "PGPASSWORD=$PGPASSWORD" "$CONTAINER" psql -U "$PG_USER" -d "$DATABASE" < "$file"
}

run_sql_data() {
  local file="$1"
  local label="$2"
  echo
  echo "===== $label ====="
  docker exec -i -e "PGPASSWORD=$PGPASSWORD" "postgres-data" psql -U "$PG_USER" -d "dashboard" < "$file"
}

# ====== 執行前安全提醒 ======
echo
echo "⚠️  執行前請確認："
echo "   1. 你 repo 裡沒有未 commit 的重要變更（git status 看看）"
echo "   2. 這個 migration 可隨時撤銷：跑 rollback_air_station_map_metrotaipei.sql"
echo
read -rp "要繼續嗎？(y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "已取消。"
  exit 0
fi

# ====== 執行 ======
echo "📦 air_station_map_metrotaipei 一鍵部署開始"

run_sql "air_station_map_metrotaipei.sql"        "Step 1：建立組件（4 筆 row）"
run_sql "verify_air_station_map_metrotaipei.sql" "Step 2：驗證"
run_sql "attach_to_dashboard_air_station_map.sql" "Step 3：掛到 dashboard [$DASHBOARD_INDEX]"
run_sql_data "add_food_safety_data_tables.sql"   "Step 4a：食安資料表 + mock（postgres-data/dashboard）"
run_sql "add_food_safety_components.sql"          "Step 4b：食安月報儀表板 metadata（dashboardmanager）"
run_sql "add_school_kitchen_wholesale_components.sql" "Step 5：學校廚房 + 農藥殘留地圖（2 組件）"

echo
echo "✅ 全部完成！重整瀏覽器看地圖"
