# Windows PowerShell 一鍵執行腳本
# 用法：
#   1. 開 PowerShell，cd 到此 migrations 資料夾
#   2. 必要時先解除執行限制：Set-ExecutionPolicy -Scope Process Bypass
#   3. 跑：.\run_all.ps1
#
# 若要改 user / dbname / container name，改下方變數

$ErrorActionPreference = "Stop"

# ====== 設定區 ======
$Container   = "postgres-manager"
$User        = "postgres"
$Database    = "dashboardmanager"
$DashboardIndex = "map-layers-metrotaipei"    # 要掛到哪個 dashboard

# 密碼（可選，未設會提示輸入）
if (-not $env:PGPASSWORD) {
    $pw = Read-Host "請輸入 $Database 的 $User 密碼" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

function Run-Sql($file, $label) {
    Write-Host ""
    Write-Host "===== $label =====" -ForegroundColor Cyan
    Get-Content $file -Raw | docker exec -i -e PGPASSWORD=$env:PGPASSWORD $Container psql -U $User -d $Database
    if ($LASTEXITCODE -ne 0) {
        throw "$label 失敗，exit code $LASTEXITCODE"
    }
}

# ====== 執行前安全提醒 ======
Write-Host ""
Write-Host "⚠️  執行前請確認：" -ForegroundColor Yellow
Write-Host "   1. 你 repo 裡沒有未 commit 的重要變更（git status 看看）" -ForegroundColor Yellow
Write-Host "   2. 這個 migration 可隨時撤銷：跑 rollback_air_station_map_metrotaipei.sql" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "要繼續嗎？(y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消。" -ForegroundColor Red
    exit 0
}

# ====== 執行 ======
Write-Host "📦 air_station_map_metrotaipei 一鍵部署開始" -ForegroundColor Green

Run-Sql "air_station_map_metrotaipei.sql"        "Step 1：建立組件（4 筆 row）"
Run-Sql "verify_air_station_map_metrotaipei.sql" "Step 2：驗證"
Run-Sql "attach_to_dashboard_air_station_map.sql" "Step 3：掛到 dashboard [$DashboardIndex]"

Write-Host ""
Write-Host "✅ 全部完成！重整瀏覽器看地圖" -ForegroundColor Green
