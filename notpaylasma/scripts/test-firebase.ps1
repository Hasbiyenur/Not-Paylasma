param([string]$JavaHome)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
if (!$JavaHome) {
    $studioJava = 'C:/Program Files/Android/Android Studio/jbr'
    if (Test-Path -LiteralPath "$studioJava/bin/java.exe") { $JavaHome = $studioJava }
}
$oldJava = $env:JAVA_HOME
$oldPath = $env:PATH
$oldCi = $env:CI
$oldCache = $env:FIREBASE_EMULATORS_PATH
Push-Location $sourceRoot
try {
    if ($JavaHome) {
        $env:JAVA_HOME = $JavaHome
        $env:PATH = "$JavaHome/bin;$env:PATH"
    }
    $env:CI = 'true'
    $env:FIREBASE_EMULATORS_PATH = Join-Path $sourceRoot '.firebase/emulators'
    # demo- projesi gerçek Firebase kaynaklarına bağlanmaz. Login/deploy yoktur.
    firebase emulators:exec --non-interactive --project demo-notpaylas --only firestore,storage 'npm --prefix scripts/firebase-tests test'
    if ($LASTEXITCODE -ne 0) { throw 'Firebase emulator testleri başarısız.' }
} finally {
    Pop-Location
    $env:JAVA_HOME = $oldJava
    $env:PATH = $oldPath
    $env:CI = $oldCi
    $env:FIREBASE_EMULATORS_PATH = $oldCache
}
