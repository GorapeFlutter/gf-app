#!/usr/bin/env bash
# Run the gf-app quality gate.
#
# `flutter analyze` can crash in some Flutter SDK builds because the
# analysis-server snapshot is missing. `dart analyze` is used instead because it
# does not depend on that snapshot.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/check.sh [options]

Options:
  --apk        Also build the debug APK.
  --no-test    Skip flutter test.
  -h, --help   Show this help.
EOF
}

build_apk=0
run_tests=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk) build_apk=1 ;;
    --no-test) run_tests=0 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

require_command dart
require_command flutter
cd "$APP_ROOT"

info "Checking formatting"
dart format --output=none --set-exit-if-changed lib test

info "Running dart analyze"
dart analyze

if [[ "$run_tests" == "1" ]]; then
  info "Running flutter test"
  flutter test
fi

if [[ "$build_apk" == "1" ]]; then
  info "Building debug APK"
  flutter build apk --debug
fi

ok "All checks passed"
