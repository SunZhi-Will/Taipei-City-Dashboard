param(
    [ValidateSet('quick-up', 'bootstrap-full', 'down', 'status')]
    [string]$Action = 'quick-up'
)

$ErrorActionPreference = 'Stop'
$dockerDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..\docker')).Path
$envFile = Join-Path $dockerDir '.env'
$envTemplate = Join-Path $dockerDir '.env.template'

function Ensure-EnvFile {
    if (-not (Test-Path $envFile)) {
        if (-not (Test-Path $envTemplate)) {
            Write-Error ".env.template not found at $envTemplate"
            exit 1
        }
        Write-Host "INFO: .env not found. Creating from template..." -ForegroundColor Cyan
        Copy-Item $envTemplate $envFile
        Write-Host "INFO: .env created. Please review $envFile and add any custom values if needed." -ForegroundColor Green
    }
}

function Ensure-Network {
    param([string]$DockerCmd)
    if (-not ((& $DockerCmd network ls --format "{{.Name}}") | Select-String -Pattern "^br_dashboard$" -Quiet)) {
        Write-Host "INFO: Creating Docker network br_dashboard..." -ForegroundColor Cyan
        & $DockerCmd network create --driver=bridge --subnet=192.168.128.0/24 --gateway=192.168.128.1 br_dashboard | Out-Null
        Write-Host "OK: br_dashboard network created" -ForegroundColor Green
    }
}

function Is-DBInitialized {
    param([string]$DockerCmd)
    $volumeList = & $DockerCmd volume ls --format "{{.Name}}" | Select-String -Pattern "^postgres_data$"
    return $null -ne $volumeList
}

function Use-WindowsDocker {
    param([string]$DockerCmd, [string]$ActionName)

    Ensure-Network -DockerCmd $DockerCmd

    if ($ActionName -eq 'quick-up') {
        $isInit = Is-DBInitialized -DockerCmd $DockerCmd
        if (-not $isInit) {
            Write-Host "INFO: First-time setup detected. Running bootstrap..." -ForegroundColor Cyan
            & $DockerCmd compose -f docker-compose-db.yaml up -d
            Start-Sleep -Seconds 8
            & $DockerCmd compose -f docker-compose-init.yaml up
        }
        Write-Host "INFO: Starting database services..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose-db.yaml up -d
        Write-Host "INFO: Waiting for database services to be ready (15 seconds)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        Write-Host "INFO: Starting application services..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose.yaml up -d
        Start-Sleep -Seconds 3
        Write-Host ""
        Write-Host "OK: Services started. Check status below:" -ForegroundColor Green
        & $DockerCmd compose -f docker-compose.yaml ps
        & $DockerCmd compose -f docker-compose-db.yaml ps
        return
    }

    if ($ActionName -eq 'bootstrap-full') {
        Write-Host "INFO: Running full bootstrap..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose-db.yaml up -d
        Write-Host "INFO: Waiting for database services to be ready (15 seconds)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        & $DockerCmd compose -f docker-compose-init.yaml up
        Write-Host "INFO: Starting application services..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose.yaml up -d --build
        Start-Sleep -Seconds 3
        Write-Host ""
        Write-Host "OK: Bootstrap complete. Services started:" -ForegroundColor Green
        & $DockerCmd compose -f docker-compose.yaml ps
        & $DockerCmd compose -f docker-compose-db.yaml ps
        return
    }

    if ($ActionName -eq 'down') {
        Write-Host "INFO: Stopping all services..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose.yaml down
        & $DockerCmd compose -f docker-compose-db.yaml down
        Write-Host "OK: Services stopped" -ForegroundColor Green
        return
    }

    if ($ActionName -eq 'status') {
        Write-Host "INFO: Checking service status..." -ForegroundColor Cyan
        & $DockerCmd compose -f docker-compose-db.yaml ps
        & $DockerCmd compose -f docker-compose.yaml ps
        return
    }
}

function Use-WSLDocker {
    param([string]$Distro, [string]$ActionName)

    $wslDockerDir = (& wsl.exe -d $Distro wslpath -a ($dockerDir -replace '\\', '/')).Trim()

    if (-not $wslDockerDir) {
        Write-Error "WSL path conversion failed: $dockerDir"
        exit 2
    }

    $networkCmd = "docker network ls --format '{{.Name}}' | grep -x 'br_dashboard' >/dev/null || docker network create --driver=bridge --subnet=192.168.128.0/24 --gateway=192.168.128.1 br_dashboard >/dev/null"
    & wsl.exe -d $Distro sh -lc $networkCmd

    if ($ActionName -eq 'quick-up') {
        $isInit = (& wsl.exe -d $Distro sh -lc "docker volume ls --format '{{.Name}}' | grep -x 'postgres_data' >/dev/null; echo `$?").Trim()
        if ($isInit -ne '0') {
            Write-Host "INFO: First-time setup detected. Running bootstrap..." -ForegroundColor Cyan
            & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose-db.yaml up -d && sleep 5 && docker compose -f docker-compose-init.yaml run --rm dashboard-be-init-manager && docker compose -f docker-compose-init.yaml run --rm dashboard-be-init-dashboard"
        }
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose-db.yaml up -d && docker compose -f docker-compose.yaml up -d"
        Write-Host ""
        Write-Host "OK: Services started. Check status below:" -ForegroundColor Green
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose.yaml ps"
        return
    }

    if ($ActionName -eq 'bootstrap-full') {
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose-db.yaml up -d && sleep 5 && docker compose -f docker-compose-init.yaml run --rm dashboard-be-init-manager && docker compose -f docker-compose-init.yaml run --rm dashboard-be-init-dashboard && docker compose -f docker-compose.yaml up -d --build dashboard-be && docker compose -f docker-compose.yaml up -d"
        Write-Host ""
        Write-Host "OK: Bootstrap complete. Services started:" -ForegroundColor Green
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose.yaml ps"
        return
    }

    if ($ActionName -eq 'down') {
        Write-Host "INFO: Stopping all services..." -ForegroundColor Cyan
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose.yaml down && docker compose -f docker-compose-db.yaml down"
        Write-Host "OK: Services stopped" -ForegroundColor Green
        return
    }

    if ($ActionName -eq 'status') {
        Write-Host "INFO: Checking service status..." -ForegroundColor Cyan
        & wsl.exe -d $Distro sh -lc "cd '$wslDockerDir' && docker compose -f docker-compose-db.yaml ps && docker compose -f docker-compose.yaml ps"
        return
    }
}

Write-Host "=== Taipei City Dashboard Deployment ===" -ForegroundColor Cyan
Write-Host ""

Ensure-EnvFile

$dockerCmd = (Get-Command docker -ErrorAction SilentlyContinue).Source
if ($dockerCmd) {
    Write-Host "INFO: Using Windows Docker at $dockerCmd" -ForegroundColor Cyan
    Use-WindowsDocker -DockerCmd $dockerCmd -ActionName $Action
    exit 0
}

$wslDistro = if ($env:WSL_DOCKER_DISTRO) { $env:WSL_DOCKER_DISTRO } else { 'Ubuntu' }
$wslDockerCheck = (& wsl.exe -d $wslDistro sh -lc "command -v docker >/dev/null 2>&1; echo `$?").Trim()

if ($wslDockerCheck -ne '0') {
    Write-Error "Docker CLI not found in Windows or WSL. Please:"
    Write-Error "1. Install Docker Desktop or use WSL docker"  
    Write-Error "2. If using WSL, set environment variable: `$env:WSL_DOCKER_DISTRO='Ubuntu'"
    Write-Error "3. Close and reopen VS Code terminal"
    exit 127
}

Write-Host "INFO: Using WSL Docker ($wslDistro)" -ForegroundColor Cyan
Use-WSLDocker -Distro $wslDistro -ActionName $Action
