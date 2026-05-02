@echo off
REM Windows cmd 一鍵執行腳本（備用，推薦用 run_all.ps1）
REM 用法：
REM   開 cmd，cd 到此 migrations 資料夾
REM   run_all.bat

setlocal enabledelayedexpansion

set MANAGER_CONTAINER=postgres-manager
set DATA_CONTAINER=postgres-data
set PG_USER=postgres
set MANAGER_DATABASE=dashboardmanager
set DATA_DATABASE=dashboard

echo.
echo ⚠️  執行前請確認：
echo    1. 你 repo 裡沒有未 commit 的重要變更（git status 看看）
echo    2. 這個 migration 可隨時撤銷：跑 rollback_air_station_map_metrotaipei.sql
echo.
set /p CONFIRM="要繼續嗎？(y/N): "
if /i not "%CONFIRM%"=="y" (
    echo 已取消。
    exit /b 0
)

if "%PGPASSWORD%"=="" (
    set /p PGPASSWORD="請輸入 PostgreSQL 使用者 %PG_USER% 的密碼: "
)

echo.
echo ===== Step 1: 建立組件 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %MANAGER_CONTAINER% psql -U %PG_USER% -d %MANAGER_DATABASE% < air_station_map_metrotaipei.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 2: 驗證 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %MANAGER_CONTAINER% psql -U %PG_USER% -d %MANAGER_DATABASE% < verify_air_station_map_metrotaipei.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 3: 掛到 dashboard =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %MANAGER_CONTAINER% psql -U %PG_USER% -d %MANAGER_DATABASE% < attach_to_dashboard_air_station_map.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 4: 建立食安資料表與 mock 資料 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %DATA_CONTAINER% psql -U %PG_USER% -d %DATA_DATABASE% < add_food_safety_data_tables.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 5: 建立食安組件 metadata =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %MANAGER_CONTAINER% psql -U %PG_USER% -d %MANAGER_DATABASE% < add_food_safety_components.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 6: 學校廚房 + 農藥殘留地圖 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %MANAGER_CONTAINER% psql -U %PG_USER% -d %MANAGER_DATABASE% < add_school_kitchen_wholesale_components.sql
if errorlevel 1 goto :error

echo.
echo ✅ 全部完成！重整瀏覽器看地圖
goto :eof

:error
echo ❌ 失敗，exit code %errorlevel%
exit /b 1
*** Add File: /Applications/Projects/Taipei-City-Dashboard/migrations/run_all.sh
#!/bin/bash

set -euo pipefail

MANAGER_CONTAINER="postgres-manager"
MANAGER_DATABASE="dashboardmanager"
DATA_CONTAINER="postgres-data"
DATA_DATABASE="dashboard"
PG_USER="postgres"
DASHBOARD_INDEX="map-layers-metrotaipei"

run_sql() {
    local file="$1"
    local label="$2"
    local container="$3"
    local database="$4"

    echo
    echo "===== ${label} ====="
    docker exec -i -e PGPASSWORD="${PGPASSWORD}" "${container}" \
        psql -U "${PG_USER}" -d "${database}" < "${file}"
}

echo
echo "WARNING: 執行前請確認："
echo "  1. 你 repo 裡沒有未 commit 的重要變更（git status 看看）"
echo "  2. 這個 migration 可隨時撤銷：跑 rollback_air_station_map_metrotaipei.sql"
echo

read -r -p "要繼續嗎？(y/N) " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "已取消。"
    exit 0
fi

if [[ -z "${PGPASSWORD:-}" ]]; then
    read -r -s -p "請輸入 PostgreSQL 使用者 ${PG_USER} 的密碼: " PGPASSWORD
    echo
    export PGPASSWORD
fi

echo "INFO: air_station_map_metrotaipei / food_safety 一鍵部署開始"

run_sql "air_station_map_metrotaipei.sql" "Step 1：建立 air station map 組件（manager DB）" "${MANAGER_CONTAINER}" "${MANAGER_DATABASE}"
run_sql "verify_air_station_map_metrotaipei.sql" "Step 2：驗證 air station map" "${MANAGER_CONTAINER}" "${MANAGER_DATABASE}"
run_sql "attach_to_dashboard_air_station_map.sql" "Step 3：掛到 dashboard [${DASHBOARD_INDEX}]" "${MANAGER_CONTAINER}" "${MANAGER_DATABASE}"
run_sql "add_food_safety_data_tables.sql" "Step 4：建立食安資料表與 mock 資料（dashboard DB）" "${DATA_CONTAINER}" "${DATA_DATABASE}"
run_sql "add_food_safety_components.sql" "Step 5：建立食安組件 metadata（manager DB）" "${MANAGER_CONTAINER}" "${MANAGER_DATABASE}"
run_sql "add_school_kitchen_wholesale_components.sql" "Step 6：補完學校廚房 + 農藥殘留地圖（manager DB）" "${MANAGER_CONTAINER}" "${MANAGER_DATABASE}"

echo
echo "OK: 全部完成，請重整瀏覽器確認畫面。"
