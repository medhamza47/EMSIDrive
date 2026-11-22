param([Parameter(Mandatory=$true)][string]$File)
$ErrorActionPreference = 'Stop'
$resolved = (Resolve-Path -LiteralPath $File).Path
$bytes = [IO.File]::ReadAllBytes($resolved)
if ($bytes.Length -gt 8MB) { throw 'Document exceeds 8 MB' }
$kind = if ([IO.Path]::GetExtension($resolved) -ieq '.pdf') { 0 } else { 1 }
$body = @{ file = [Convert]::ToBase64String($bytes); fileType = $kind; visualize = $false; returnMarkdownImages = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri 'http://localhost:8090/layout-parsing' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 600 | ConvertTo-Json -Depth 60
