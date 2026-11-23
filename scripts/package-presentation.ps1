[CmdletBinding()]
param(
    [string]$JavaHome = 'C:\Program Files\Android\Android Studio\jbr',
    [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\sdk",
    [switch]$PrepareOnly,
    [switch]$ArchiveOnly
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$handoff = Join-Path $repoRoot 'handoff'
$bundle = Join-Path $handoff 'EMSIDrive-Presentation'
$archive = Join-Path $handoff 'EMSIDrive-Presentation.zip'
if (-not $ArchiveOnly) {
    $files = @{
        'app.jar' = Join-Path $repoRoot 'backend\target\emsidrive-api-0.0.1-SNAPSHOT.jar'
        'EMSIDrive.apk' = Join-Path $repoRoot 'mobile\build\app\outputs\flutter-apk\app-debug.apk'
        '.env.local' = Join-Path $repoRoot 'backend\.env.local'
    }
    foreach ($source in $files.Values) {
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing $source. Build the backend JAR and localhost:8080 debug APK first." }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $JavaHome 'bin\java.exe'))) { throw "Java runtime missing: $JavaHome" }
    if (-not (Test-Path -LiteralPath (Join-Path $AndroidSdk 'platform-tools\adb.exe'))) { throw "ADB missing in $AndroidSdk" }
    New-Item -ItemType Directory -Path $bundle -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'presentation\*') -Destination $bundle -Recurse -Force
    foreach ($name in $files.Keys) { Copy-Item -LiteralPath $files[$name] -Destination (Join-Path $bundle $name) -Force }
    $runtime = Join-Path $bundle 'runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    Copy-Item -Path (Join-Path $JavaHome '*') -Destination $runtime -Recurse -Force
    $android = Join-Path $bundle 'android'
    New-Item -ItemType Directory -Path $android -Force | Out-Null
    foreach ($name in @('adb.exe', 'AdbWinApi.dll', 'AdbWinUsbApi.dll', 'libwinpthread-1.dll', 'NOTICE.txt', 'source.properties')) {
        $source = Join-Path $AndroidSdk "platform-tools\$name"
        if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $android -Force }
    }
    Write-Host "Prepared runnable presentation folder: $bundle"
}
if ($PrepareOnly) { return }
if (-not (Test-Path -LiteralPath (Join-Path $bundle 'sample-timetable.png'))) { throw 'The presentation sample is missing.' }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($archive, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -LiteralPath $bundle -Recurse -File -Force) {
        $relative = $file.FullName.Substring($bundle.Length + 1).Replace('\', '/')
        if ($relative -in @('session.json', 'api.log', 'api-error.log')) { continue }
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relative,
            [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $zip.Dispose() }
Write-Host "Ready to send privately: $archive"
Write-Host ('Size: {0:N1} MB' -f ((Get-Item -LiteralPath $archive).Length / 1MB))
