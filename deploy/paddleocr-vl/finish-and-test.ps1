$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
$adbRuntime='emsidrive-ocr-python-runtime'
$deadline=(Get-Date).AddMinutes(40)
while ((Get-Date) -lt $deadline) {
    docker exec $adbRuntime sh -c 'test -f /tmp/python-ready && dpkg -s libgl1 libglib2.0-0t64 libgomp1 >/dev/null 2>&1' 2>$null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 10
}
if ((Get-Date) -ge $deadline) { throw 'Runtime installation did not complete within 40 minutes. Inspect pinned-install.log and system-install.log inside the runtime container.' }
docker cp start.py "${adbRuntime}:/start.py"
docker commit $adbRuntime emsidrive-ocr-paddleocr:tested-runtime
if ($LASTEXITCODE -ne 0) { throw 'Cannot save runtime image' }
docker run -d --name emsidrive-paddleocr-service --shm-size 2g -p 127.0.0.1:8090:8080 --mount type=volume,source=emsidrive-paddle-model,target=/models,readonly --mount type=volume,source=emsidrive-ocr_models,target=/root/.paddlex emsidrive-ocr-paddleocr:tested-runtime python /start.py
if ($LASTEXITCODE -ne 0) { throw 'Cannot start model service' }
$bytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '../../presentation/sample-timetable.png'))
$body=@{file=[Convert]::ToBase64String($bytes);fileType=1}|ConvertTo-Json -Compress
$deadline=(Get-Date).AddMinutes(30)
while ((Get-Date) -lt $deadline) {
    try { Invoke-WebRequest -UseBasicParsing 'http://localhost:8090/docs' -TimeoutSec 3 | Out-Null; break } catch { Start-Sleep -Seconds 10 }
}
$result=Invoke-RestMethod 'http://localhost:8090/layout-parsing' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 900
$result | ConvertTo-Json -Depth 80 | Set-Content -Encoding UTF8 smoke-result.json
if ($result.errorCode -ne 0 -or !$result.result.layoutParsingResults) { throw 'Model returned no page results' }
Write-Output 'MODEL SMOKE RESPONSE SAVED: smoke-result.json. Inspect recognized times before accepting accuracy.'
