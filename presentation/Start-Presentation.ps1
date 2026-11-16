[CmdletBinding()]
param(
    [ValidateRange(1024, 65535)][int]$ApiPort = 18080,
    [ValidateRange(1024, 65535)][int]$DatabasePort = 15433,
    [ValidatePattern('^[a-z0-9][a-z0-9-]+$')][string]$ProjectName = 'emsidrive-presentation',
    [string]$DeviceId,
    [switch]$SkipPhone
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$env:PRESENTATION_DB_PORT = [string]$DatabasePort
$stateFile = Join-Path $PSScriptRoot 'session.json'
$java = Join-Path $PSScriptRoot 'runtime\bin\java.exe'
$adb = Join-Path $PSScriptRoot 'android\adb.exe'
$apiUrl = "http://127.0.0.1:$ApiPort"

function Assert-NativeSuccess([string]$operation) {
    if ($LASTEXITCODE -ne 0) { throw "$operation failed (exit $LASTEXITCODE)." }
}
function Test-Api {
    try {
        $health = Invoke-RestMethod "$apiUrl/health" -TimeoutSec 2
        return $health.status -eq 'UP' -and $health.application -eq 'emsidrive-api'
    } catch { return $false }
}

foreach ($file in @($java, $adb, 'app.jar', 'EMSIDrive.apk', '.env.local', 'compose.yaml')) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Missing $file. Extract the complete presentation ZIP first."
    }
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Install Docker Desktop for Windows, restart Windows if requested, then run START.cmd again.'
}
& docker info --format '{{.OSType}}' *> $null
if ($LASTEXITCODE -ne 0) {
    $desktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (Test-Path -LiteralPath $desktop) {
        Start-Process -FilePath $desktop -WindowStyle Hidden
        Write-Host 'Waiting for Docker Desktop...'
        for ($i = 0; $i -lt 90; $i++) {
            & docker info --format '{{.OSType}}' *> $null
            if ($LASTEXITCODE -eq 0) { break }
            Start-Sleep -Seconds 2
        }
    }
    if ($LASTEXITCODE -ne 0) { throw 'Docker is not ready. Open Docker Desktop and enable Linux containers.' }
}
Write-Host 'Starting the presentation database...'
& docker compose -p $ProjectName -f compose.yaml up -d --wait --wait-timeout 120
Assert-NativeSuccess 'Database startup'

$existingSession = $null
if (Test-Path -LiteralPath $stateFile) {
    $existingSession = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
}
if (Test-Api) {
    if (-not $existingSession -or $existingSession.apiPort -ne $ApiPort) {
        throw "Port $ApiPort already hosts another API. Run with -ApiPort 18081, or stop that API first."
    }
    Write-Host "Presentation API already running at $apiUrl"
} else {
    Write-Host 'Starting the bundled backend with the shared AI configuration...'
    $arguments = @('-Djava.awt.headless=true', '-jar', 'app.jar', '--spring.profiles.active=dev',
        "--server.port=$ApiPort", '--server.address=127.0.0.1',
        "--spring.datasource.url=jdbc:postgresql://127.0.0.1:$DatabasePort/emsidrive",
        '--spring.datasource.username=emsidrive', '--spring.datasource.password=emsidrive',
        '--spring.jpa.show-sql=false', '--debug=false', '--logging.level.root=INFO', '--logging.level.ma.emsi.emsidrive=INFO')
    $process = Start-Process -FilePath $java -ArgumentList $arguments -WorkingDirectory $PSScriptRoot `
        -RedirectStandardOutput (Join-Path $PSScriptRoot 'api.log') `
        -RedirectStandardError (Join-Path $PSScriptRoot 'api-error.log') -WindowStyle Hidden -PassThru
    @{ processId = $process.Id; startedAt = $process.StartTime.ToUniversalTime().ToString('o');
        apiPort = $ApiPort; databasePort = $DatabasePort; projectName = $ProjectName } |
        ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    for ($i = 0; $i -lt 120; $i++) {
        if (Test-Api) { break }
        $process.Refresh()
        if ($process.HasExited) {
            Get-Content api.log -Tail 25
            throw 'The backend exited. See api.log and api-error.log.'
        }
        Start-Sleep -Seconds 1
    }
    if (-not (Test-Api)) { throw 'The API did not start. See api.log and api-error.log.' }
    Write-Host "Backend and database ready: $apiUrl"
}
if ($SkipPhone) { return }

& $adb start-server
Assert-NativeSuccess 'ADB startup'
$deviceLines = @(& $adb devices)
Assert-NativeSuccess 'Phone detection'
$connected = @($deviceLines | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
if (-not $DeviceId) {
    if ($connected.Count -eq 0) {
        $deviceLines | Write-Host
        throw 'Unlock the phone, enable USB debugging, use a data USB cable, and accept Allow USB debugging. Then run START.cmd again.'
    }
    if ($connected.Count -gt 1) {
        throw ('Several phones are connected. Use -DeviceId with one of: ' + ($connected -join ', '))
    }
    $DeviceId = $connected[0]
}
if ($DeviceId -notin $connected) { throw "Phone $DeviceId is not connected and authorized." }
& $adb -s $DeviceId reverse tcp:8080 "tcp:$ApiPort"
Assert-NativeSuccess 'USB API connection'
Write-Host 'Installing EMSIDrive. Accept any installation prompt on the phone...'
& $adb -s $DeviceId install -r EMSIDrive.apk
Assert-NativeSuccess 'APK installation (if a different signing key was used, uninstall that old app manually first)'
& $adb -s $DeviceId shell am start -n ma.emsi.emsidrive.emsidrive_mobile/.MainActivity
Assert-NativeSuccess 'App launch'
Write-Host ''
Write-Host 'EMSIDrive is ready. Keep the USB cable connected and this computer awake.' -ForegroundColor Green
Write-Host 'Register a new @emsi-edu.ma account on this presentation database.'
Write-Host 'Run CHECK-AI.cmd to verify the real timetable analysis before presenting.'
