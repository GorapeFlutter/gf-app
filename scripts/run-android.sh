#!/usr/bin/env bash
# Run gf-app on a connected Android device or emulator.
#
# The app reaches the host through adb reverse, so the OIDC issuer stays
# http://localhost:8080/realms/gorape and matches Keycloak's `iss` claim.
# This works for both emulators and physical devices. The default connection
# settings (10.0.2.2 on Android) remain unchanged for manual `flutter run`.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/run-android.sh [options] [-- flutter-run-args...]

Options:
  --device ID       Target device (default: Flutter's selection)
  --api-url URL     API base URL (default: http://localhost:8000)
  --issuer URL      OIDC issuer (default: http://localhost:8080/realms/gorape)
  --release         Build/run in release mode
  --skip-checks     Do not require the backend health endpoints to be up
  -h, --help        Show this help

Environment:
  GORAPE_API_BASE_URL, GORAPE_OIDC_ISSUER
EOF
}

device=""
api_url="${GORAPE_API_BASE_URL:-http://localhost:8000}"
issuer="${GORAPE_OIDC_ISSUER:-http://localhost:8080/realms/gorape}"
flutter_mode="--debug"
skip_checks=0
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      [[ $# -ge 2 ]] || die "--device requires a value"
      device="$2"
      shift
      ;;
    --api-url)
      [[ $# -ge 2 ]] || die "--api-url requires a value"
      api_url="$2"
      shift
      ;;
    --issuer)
      [[ $# -ge 2 ]] || die "--issuer requires a value"
      issuer="$2"
      shift
      ;;
    --release) flutter_mode="--release" ;;
    --skip-checks) skip_checks=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      extra_args=("$@")
      break
      ;;
    *) extra_args+=("$1") ;;
  esac
  shift
done

require_command adb
require_command flutter
require_command curl

devices="$(adb_required)"
if [[ -z "$device" ]]; then
  device="$(printf '%s\n' "$devices" | head -n 1)"
fi
printf '%s\n' "$devices" | grep -qx "$device" ||
  die "Device '$device' is not connected. Available: $(printf '%s ' $devices)"

if [[ "$skip_checks" != "1" ]]; then
  curl -fsS --max-time 5 "$api_url/health" >/dev/null 2>&1 ||
    die "Gorape API is not reachable at $api_url. Start it with ./scripts/gorape-up.sh."
  curl -fsS --max-time 5 \
    "${issuer%/}/.well-known/openid-configuration" >/dev/null 2>&1 ||
    die "Keycloak is not reachable at $issuer. Start it with ./scripts/gorape-up.sh."
fi

info "Configuring adb reverse for $device"
# API and OIDC both use localhost from the app's point of view.
adb -s "$device" reverse tcp:8080 tcp:8080 >/dev/null
adb -s "$device" reverse tcp:8000 tcp:8000 >/dev/null
ok "localhost:8080 and localhost:8000 now reach the host"

cd "$APP_ROOT"
info "Running gf-app on $device"
if [[ ${#extra_args[@]} -gt 0 ]]; then
  exec flutter run \
    -d "$device" \
    "$flutter_mode" \
    --dart-define="GORAPE_API_BASE_URL=$api_url" \
    --dart-define="GORAPE_OIDC_ISSUER=$issuer" \
    "${extra_args[@]}"
fi
exec flutter run \
  -d "$device" \
  "$flutter_mode" \
  --dart-define="GORAPE_API_BASE_URL=$api_url" \
  --dart-define="GORAPE_OIDC_ISSUER=$issuer"
