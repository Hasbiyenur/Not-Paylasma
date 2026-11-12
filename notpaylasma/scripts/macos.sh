#!/usr/bin/env bash
set -euo pipefail

action="${1:-run}"
case "$action" in
  run|check|build|diagnose) ;;
  *) echo 'Kullanım: bash scripts/macos.sh [run|check|build|diagnose]' >&2; exit 2 ;;
esac
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'macOS derlemesi için bu betiği Mac üzerinde çalıştırın.' >&2
  exit 1
fi
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
key_file="$project_root/.local/firebase-keys.json"
dart scripts/prepare_firebase.dart
if [[ "$action" == diagnose ]]; then
  mkdir -p build/diagnostics
  log_file="$project_root/build/diagnostics/macos.log"
  echo "Tanılama çıktısı: $log_file"
  if (
    set +e
    echo '=== macOS / mimari ==='
    sw_vers
    uname -m
    echo '=== Flutter / Dart ==='
    command -v flutter
    command -v dart
    flutter --version
    dart --version
    echo '=== Xcode / CocoaPods ==='
    xcode-select -p
    xcodebuild -version
    pod --version
    echo '=== İmzalama yapılandırması ==='
    grep -E 'CODE_SIGN_IDENTITY|PRODUCT_BUNDLE_IDENTIFIER' macos/Runner/Configs/AppInfo.xcconfig
    echo '=== Flutter doctor ==='
    flutter doctor -v
    echo '=== Bağımlılık çözümü ==='
    flutter pub get
    dependency_status=$?
    if [[ "$dependency_status" -ne 0 ]]; then
      exit "$dependency_status"
    fi
    echo '=== macOS debug derlemesi ==='
    flutter build macos --debug --verbose "--dart-define-from-file=$key_file"
  ) 2>&1 | tee "$log_file"; then
    echo "Derleme başarılı. Tanılama: $log_file"
  else
    echo "Derleme/kurulum hatası kaydedildi: $log_file" >&2
    exit 1
  fi
  exit 0
fi

for tool in flutter xcodebuild pod; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Eksik araç: $tool. docs/MACOS_KURULUM.md dosyasındaki kurulumu tamamlayın." >&2
    exit 1
  fi
done
# CLI araçları tek başına yeterli değildir; tam Xcode ve lisansı gerekir.
xcodebuild -version
flutter pub get
case "$action" in
  run) exec flutter run -d macos "--dart-define-from-file=$key_file" ;;
  check)
    flutter analyze
    flutter test
    flutter build macos --debug "--dart-define-from-file=$key_file"
    ;;
  build) exec flutter build macos --release "--dart-define-from-file=$key_file" ;;
esac
