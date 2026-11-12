#!/usr/bin/env bash
set -euo pipefail

action="${1:-run}"
case "$action" in
  run|check|build) ;;
  *) echo 'Kullanım: bash scripts/macos.sh [run|check|build]' >&2; exit 2 ;;
esac
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'macOS derlemesi için bu betiği Mac üzerinde çalıştırın.' >&2
  exit 1
fi
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
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
  run) exec flutter run -d macos ;;
  check)
    flutter analyze
    flutter test
    flutter build macos --debug
    ;;
  build) exec flutter build macos --release ;;
esac
