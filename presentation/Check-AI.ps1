param([ValidateRange(1024, 65535)][int]$ApiPort = 18080)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$base = "http://127.0.0.1:$ApiPort"
$credentials = @{ email = 'presentation-check@emsi-edu.ma'; password = 'Presentation2026!' }
$registration = @{ email = $credentials.email; password = $credentials.password;
    fullName = 'Presentation Check'; phoneNumber = '+212600000000' }
try {
    $session = Invoke-RestMethod "$base/api/v1/auth/register" -Method Post -ContentType 'application/json' `
        -Body ($registration | ConvertTo-Json)
} catch {
    if (-not $_.Exception.Response -or [int]$_.Exception.Response.StatusCode -ne 409) { throw }
    $session = Invoke-RestMethod "$base/api/v1/auth/login" -Method Post -ContentType 'application/json' `
        -Body ($credentials | ConvertTo-Json)
}
$headers = @{ Authorization = 'Bearer ' + $session.accessToken }
$profile = Invoke-RestMethod "$base/api/v1/me" -Headers $headers
Write-Host ('Account and profile OK: ' + $profile.email)
Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(120)
$form = New-Object System.Net.Http.MultipartFormDataContent
try {
    $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $session.accessToken)
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'sample-timetable.png'))
    $content = New-Object System.Net.Http.ByteArrayContent -ArgumentList @(,$bytes)
    $content.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue('image/png')
    $form.Add($content, 'file', 'sample-timetable.png')
    $form.Add((New-Object System.Net.Http.StringContent('DEMO')), 'group')
    $response = $client.PostAsync("$base/api/v1/schedules/imports", $form).GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if (-not $response.IsSuccessStatusCode) { throw "Import failed ($([int]$response.StatusCode)): $body" }
    $job = $body | ConvertFrom-Json
} finally { $form.Dispose(); $client.Dispose() }
Write-Host 'Testing the real AI timetable analysis...'
$deadline = [DateTime]::UtcNow.AddSeconds(150)
do {
    Start-Sleep -Seconds 2
    $job = Invoke-RestMethod "$base/api/v1/schedules/imports/$($job.id)" -Headers $headers
} while ($job.status -in @('QUEUED', 'PROCESSING') -and [DateTime]::UtcNow -lt $deadline)
if ($job.status -ne 'SUCCEEDED') { throw "AI check failed: $($job.status) $($job.errorCode). Check internet access, provider quota and api.log." }
$validSlots = @($job.draft.slots | Where-Object { $_.weekday -and $_.startTime -and $_.endTime })
if ($validSlots.Count -lt 3) { throw "AI returned only $($validSlots.Count) usable lessons for the three-lesson sample. Review the draft before presenting." }
$validSlots | Select-Object label,weekday,startTime,endTime | Format-Table -AutoSize
Write-Host 'PASS: registration, authentication, profile, database, background import and live AI analysis.' -ForegroundColor Green
Write-Host 'Check account: presentation-check@emsi-edu.ma / Presentation2026!'
