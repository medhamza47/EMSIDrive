# Starts the EMSIDrive backend the way the mobile app expects to find it:
# PostgreSQL container up, Spring Boot API on the selected port (default 8080).
#
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\start-backend.ps1
# Use -Port 8081 when another service occupies port 8080.
#
# Idempotent: safe to run when the stack is already up.

param(
    [ValidateRange(1, 65535)]
    [int]$Port = 8080,
    [string]$FirebaseCredentials = (Join-Path $env:LOCALAPPDATA 'EMSIDrive\firebase-service-account.json')
)

$ErrorActionPreference = 'Stop'
$apiBaseUrl = "http://localhost:$Port"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$javaHome = 'C:\Program Files\Android\Android Studio\jbr'

if (Test-Path -LiteralPath $FirebaseCredentials -PathType Leaf) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path -LiteralPath $FirebaseCredentials).Path
    $env:PUSH_ENABLED = 'true'
}

function Test-ApiUp {
    try {
        $response = Invoke-RestMethod -Uri "$apiBaseUrl/health" -TimeoutSec 3
        return $response.status -eq 'UP' -and $response.application -eq 'emsidrive-api'
    } catch {
        return $false
    }
}

if (Test-ApiUp) {
    Write-Host "API already running on $apiBaseUrl" -ForegroundColor Green
    exit 0
}

if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    throw "Port $Port is occupied by another service. Run this script with -Port and an available port, and use the same port in the mobile API_BASE_URL."
}

Write-Host 'Starting PostgreSQL container...' -ForegroundColor Cyan
Push-Location $backendDir
try {
    docker compose up -d
    if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }

    # Wait for the healthcheck so Flyway does not race an unready database.
    for ($i = 0; $i -lt 60; $i++) {
        $health = docker inspect --format '{{.State.Health.Status}}' emsidrive-postgres 2>$null
        if ($health -eq 'healthy') { break }
        Start-Sleep -Seconds 1
    }
    Write-Host "PostgreSQL status: $health" -ForegroundColor Cyan

    if (-not (Test-Path $javaHome)) {
        throw "JAVA_HOME not found at $javaHome - update `$javaHome in this script."
    }
    $env:JAVA_HOME = $javaHome
    $env:SERVER_PORT = "$Port"

    Write-Host 'Starting Spring Boot API (profile dev)...' -ForegroundColor Cyan
    $logPath = Join-Path $env:TEMP 'emsidrive-api.log'
    $process = Start-Process -FilePath 'mvn.cmd' `
        -ArgumentList 'spring-boot:run', '-Dspring-boot.run.profiles=dev', '-Dspring-boot.run.arguments=--debug=false' `
        -WorkingDirectory $backendDir `
        -RedirectStandardOutput $logPath `
        -RedirectStandardError "$logPath.err" `
        -PassThru -WindowStyle Hidden

    Write-Host "API process id $($process.Id), log: $logPath" -ForegroundColor Cyan

    for ($i = 0; $i -lt 120; $i++) {
        if (Test-ApiUp) {
            Write-Host "API is UP on $apiBaseUrl" -ForegroundColor Green
            exit 0
        }
        Start-Sleep -Seconds 1
    }

    throw "API did not answer /health within 120s. Inspect $logPath"
} finally {
    Pop-Location
}
