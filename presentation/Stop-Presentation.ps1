$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$stateFile = Join-Path $PSScriptRoot 'session.json'
if (-not (Test-Path -LiteralPath $stateFile)) { Write-Host 'No presentation session recorded.'; return }
$session = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
$process = Get-Process -Id $session.processId -ErrorAction SilentlyContinue
if ($process) {
    $expectedPath = Join-Path $PSScriptRoot 'runtime\bin\java.exe'
    $expectedTime = [DateTime]::Parse($session.startedAt).ToUniversalTime()
    if ($process.Path -ne $expectedPath -or [Math]::Abs(($process.StartTime.ToUniversalTime() - $expectedTime).TotalSeconds) -gt 1) {
        throw 'The recorded process has changed. No process was stopped.'
    }
    Stop-Process -Id $process.Id
}
$env:PRESENTATION_DB_PORT = [string]$session.databasePort
& docker compose -p $session.projectName -f compose.yaml stop
if ($LASTEXITCODE -ne 0) { throw 'Could not stop the presentation database.' }
Remove-Item -LiteralPath $stateFile
Write-Host 'Presentation stopped. Accounts and saved timetables remain in the database.'
