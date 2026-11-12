param([string]$Device = 'chrome')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    dart scripts/prepare_firebase.dart
    if ($LASTEXITCODE -ne 0) { throw 'Yerel Firebase ayarı eksik.' }
    $keyFile = Join-Path $projectRoot '.local/firebase-keys.json'
    $deviceArgs = @()
    if ($Device -eq 'chrome') { $deviceArgs = @('--web-port', '8767') }
    flutter run -d $Device "--dart-define-from-file=$keyFile" @deviceArgs
    if ($LASTEXITCODE -ne 0) { throw 'Uygulama başlatılamadı.' }
} finally {
    Pop-Location
}