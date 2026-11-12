param([switch]$BuildWeb, [switch]$BuildFirebaseWeb, [switch]$BrowserTests)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$checkRoot = Join-Path $env:TEMP ('notpaylas_check_' + [guid]::NewGuid().ToString('N'))
if ($checkRoot -match '[^\x00-\x7F]') {
    throw 'Geçici dizin ASCII olmalı. TEMP için uygun bir dizin seçin.'
}
New-Item -ItemType Directory -Path $checkRoot | Out-Null

# Asıl proje yerinde kalır. Üretilmiş önbellekler taşınmaz.
foreach ($item in @('lib', 'test', 'web', 'assets', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $item) -Destination $checkRoot -Recurse
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot 'web_test')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'web_test') -Destination $checkRoot -Recurse
}

Push-Location $checkRoot
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Paket çözümü başarısız.' }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analiz başarısız.' }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Testler başarısız.' }
    if ($BrowserTests) {
        flutter test --platform chrome test/browser/json_browser_test.dart --reporter expanded
        if ($LASTEXITCODE -ne 0) { throw 'Chrome JSON test failed.' }
    }
    if ($BuildWeb) {
        flutter build web
        if ($LASTEXITCODE -ne 0) { throw 'Web derlemesi başarısız.' }
    }
    if ($BuildFirebaseWeb) {
        flutter build web --target lib/main_firebase.dart --output build/firebase-web
        if ($LASTEXITCODE -ne 0) { throw 'Firebase web build failed.' }
    }
    Write-Output "Doğrulama tamamlandı. Çalışma kopyası: $checkRoot"
} finally {
    Pop-Location
}
