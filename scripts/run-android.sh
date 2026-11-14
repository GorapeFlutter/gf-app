#!/usr/bin/env bash
# Run gf-app on a connected Android device or emulator.
#
# The app reaches the host through adb reverse. The Gorape API uses local HTTPS
# and its development CA is passed to the debug Dart HTTP client. The OIDC
# issuer remains HTTP on localhost and matches Keycloak's `iss` claim.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/run-android.sh [options] [-- flutter-run-args...]

Options:
  --device ID       Target device (default: Flutter's selection)
  --api-url URL     API base URL (default: https://localhost:8443)
  --tls-ca FILE     CA PEM for the API TLS certificate (default: generated CA)
  --issuer URL      OIDC issuer (default: http://localhost:8080/realms/gorape)
  --release         Build/run in release mode
  --skip-checks     Do not require the backend health endpoints to be up
  -h, --help        Show this help

Environment:
  GORAPE_API_BASE_URL, GORAPE_OIDC_ISSUER, GORAPE_TLS_CA_FILE
EOF
}

device=""
api_url="${GORAPE_API_BASE_URL:-https://localhost:8443}"
issuer="${GORAPE_OIDC_ISSUER:-http://localhost:8080/realms/gorape}"
tls_ca_file="${GORAPE_TLS_CA_FILE:-}"
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
    --tls-ca)
      [[ $# -ge 2 ]] || die "--tls-ca requires a file path"
      tls_ca_file="$2"
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

if [[ -z "$tls_ca_file" && "$api_url" == https://localhost:8443* ]]; then
  tls_ca_file="$APP_ROOT/config/generated/tls/ca.crt"
fi
tls_ca_arg=""
if [[ -n "$tls_ca_file" ]]; then
  [[ -s "$tls_ca_file" ]] || die "TLS CA certificate not found: $tls_ca_file"
  [[ "$flutter_mode" != "--release" ]] ||
    die "The local development CA is debug-only; use a publicly trusted certificate for release builds."
  ca_base64="$(base64 < "$tls_ca_file" | tr -d '\r\n')"
  tls_ca_arg="--dart-define=GORAPE_TLS_CA_CERT_BASE64=$ca_base64"
fi

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
  if [[ -n "$tls_ca_file" ]]; then
    curl -fsS --cacert "$tls_ca_file" --max-time 5 "$api_url/health" >/dev/null 2>&1 ||
      die "Gorape API is not reachable at $api_url using CA $tls_ca_file. Start it with ./scripts/gorape-up.sh --https."
  else
    curl -fsS --max-time 5 "$api_url/health" >/dev/null 2>&1 ||
      die "Gorape API is not reachable at $api_url. Start it with ./scripts/gorape-up.sh."
  fi
  curl -fsS --max-time 5 \
    "${issuer%/}/.well-known/openid-configuration" >/dev/null 2>&1 ||
    die "Keycloak is not reachable at $issuer. Start it with ./scripts/gorape-up.sh."
fi

info "Configuring adb reverse for $device"
# API and OIDC use localhost from the app's point of view.
adb -s "$device" reverse tcp:8080 tcp:8080 >/dev/null
adb -s "$device" reverse tcp:8000 tcp:8000 >/dev/null
adb -s "$device" reverse tcp:8443 tcp:8443 >/dev/null
ok "localhost:8080, localhost:8000, and localhost:8443 now reach the host"

cd "$APP_ROOT"
info "Running gf-app on $device"
if [[ ${#extra_args[@]} -gt 0 ]]; then
  run_args=(
    -d "$device"
    "$flutter_mode"
    "--dart-define=GORAPE_API_BASE_URL=$api_url"
    "--dart-define=GORAPE_OIDC_ISSUER=$issuer"
  )
  [[ -z "$tls_ca_arg" ]] || run_args+=("$tls_ca_arg")
  run_args+=("${extra_args[@]}")
  exec flutter run "${run_args[@]}"
fi
run_args=(
  -d "$device"
  "$flutter_mode"
  "--dart-define=GORAPE_API_BASE_URL=$api_url"
  "--dart-define=GORAPE_OIDC_ISSUER=$issuer"
)
[[ -z "$tls_ca_arg" ]] || run_args+=("$tls_ca_arg")
exec flutter run "${run_args[@]}"
