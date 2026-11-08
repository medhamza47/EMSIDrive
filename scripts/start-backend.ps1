# Starts the EMSIDrive backend the way the mobile app expects to find it:
# PostgreSQL container up, Spring Boot API listening on 8080, /health answering.
#
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\start-backend.ps1
#
# Idempotent: safe to run when the stack is already up.

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$javaHome = 'C:\Program Files\Android\Android Studio\jbr'

function Test-ApiUp {
    try {
        $response = Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

if (Test-ApiUp) {
    Write-Host 'API already running on http://localhost:8080' -ForegroundColor Green
    exit 0
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
            Write-Host 'API is UP on http://localhost:8080' -ForegroundColor Green
            exit 0
        }
        Start-Sleep -Seconds 1
    }

    throw "API did not answer /health within 120s. Inspect $logPath"
} finally {
    Pop-Location
}
