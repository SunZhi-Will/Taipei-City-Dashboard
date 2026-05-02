@echo off
REM Windows cmd 一鍵執行腳本（備用，推薦用 run_all.ps1）
REM 用法：
REM   開 cmd，cd 到此 migrations 資料夾
REM   run_all.bat

setlocal enabledelayedexpansion

set CONTAINER=postgres-manager
set PG_USER=postgres
set DATABASE=dashboardmanager

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
    set /p PGPASSWORD="請輸入 %DATABASE% 的 %PG_USER% 密碼: "
)

echo.
echo ===== Step 1: 建立組件 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %CONTAINER% psql -U %PG_USER% -d %DATABASE% < air_station_map_metrotaipei.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 2: 驗證 =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %CONTAINER% psql -U %PG_USER% -d %DATABASE% < verify_air_station_map_metrotaipei.sql
if errorlevel 1 goto :error

echo.
echo ===== Step 3: 掛到 dashboard =====
docker exec -i -e PGPASSWORD=%PGPASSWORD% %CONTAINER% psql -U %PG_USER% -d %DATABASE% < attach_to_dashboard_air_station_map.sql
if errorlevel 1 goto :error

echo.
echo ✅ 全部完成！重整瀏覽器看地圖
goto :eof

:error
echo ❌ 失敗，exit code %errorlevel%
exit /b 1
