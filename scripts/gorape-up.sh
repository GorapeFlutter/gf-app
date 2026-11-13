#!/usr/bin/env bash
# Start the Gorape backend used by gf-app.
#
# The script reuses the backend repository's own Docker Compose files. It only
# appends gf-app overrides, and never edits the Gorape checkout.
#
# Examples:
#   ./scripts/gorape-up.sh                          # build from ../gorape
#   ./scripts/gorape-up.sh --android-attestation    # + generated trust anchors
#   ./scripts/gorape-up.sh --hub                    # gorapeflutter/gorape:latest
#   ./scripts/gorape-up.sh --hub gorapeflutter/gorape:sha-7d9703b
#   ./scripts/gorape-up.sh --all                    # also pgadmin/swagger/godoc/localstack

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/gorape-up.sh [options]

Options:
  --hub [REF]                 Use the published Docker Hub image instead of
                              building the local checkout. REF defaults to
                              GORAPE_SERVER_IMAGE or gorapeflutter/gorape:latest.
  --local                     Build from the Gorape checkout (default).
  --android-attestation       Require and mount the generated Android trust
                              anchors (fails if they are missing).
  --no-android-attestation    Ignore generated trust anchors even if present.
  --all                       Start every Compose service, including pgadmin,
                              swagger-ui, godoc and localstack.
  --server-only               Start only the server service (dependencies must
                              already be running).
  --no-build                  Do not rebuild the server image in local mode.
  --pull                      Pull the image before starting (hub mode).
  --no-wait                   Do not wait for health endpoints.
  -h, --help                  Show this help.

Environment:
  GORAPE_BACKEND_DIR          Gorape checkout (default: ../gorape)
  GORAPE_SERVER_IMAGE         Docker Hub image reference
EOF
}

mode="local"
image_ref="${GORAPE_SERVER_IMAGE:-}"
requested_attestation="auto"
all_services=0
server_only=0
do_build=1
do_pull=0
do_wait=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub)
      mode="hub"
      if [[ $# -ge 2 && "$2" != -* ]]; then
        image_ref="$2"
        shift
      fi
      ;;
    --local) mode="local" ;;
    --android-attestation) requested_attestation="yes" ;;
    --no-android-attestation) requested_attestation="no" ;;
    --all) all_services=1 ;;
    --server-only) server_only=1 ;;
    --no-build) do_build=0 ;;
    --pull) do_pull=1 ;;
    --no-wait) do_wait=0 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

require_command docker
require_command curl
require_backend

if [[ "${GORAPE_USE_HUB_IMAGE:-0}" == "1" && "$mode" == "local" ]]; then
  mode="hub"
fi

extra_files=()

if [[ "$mode" == "hub" ]]; then
  image_ref="${image_ref:-gorapeflutter/gorape:latest}"
  if [[ "$image_ref" == "gorapeflutter/gorape:latest" ]]; then
    warn "Using the floating 'latest' tag. Pin a tag or digest for reproducible runs."
  fi
  export GORAPE_SERVER_IMAGE="$image_ref"
  extra_files+=("$APP_ROOT/docker/server.image.yaml")
  info "Server image: $image_ref"
else
  info "Server source: $BACKEND_DIR (local build)"
fi

generated_config="$GENERATED_DIR/server.yaml"
generated_roots="$GENERATED_DIR/android-attestation-roots.pem"
use_attestation=0
case "$requested_attestation" in
  yes) use_attestation=1 ;;
  auto)
    if [[ -f "$generated_config" && -f "$generated_roots" ]]; then
      use_attestation=1
    fi
    ;;
esac

if [[ "$use_attestation" == "1" ]]; then
  [[ -f "$generated_config" ]] ||
    die "Missing $generated_config. Run ./scripts/generate-android-trust-config.sh."
  [[ -f "$generated_roots" ]] ||
    die "Missing $generated_roots. Run ./scripts/generate-android-trust-config.sh."
  export GORAPE_SERVER_CONFIG="$generated_config"
  export GORAPE_ANDROID_ATTESTATION_ROOTS="$generated_roots"
  extra_files+=("$APP_ROOT/docker/server.android-attestation.yaml")
  info "Android attestation: enabled ($generated_roots)"
else
  info "Android attestation: backend default (verifier reports 'unconfigured')"
fi

if [[ ${#extra_files[@]} -gt 0 ]]; then
  GORAPE_EXTRA_COMPOSE_FILES="$(printf '%s\n' "${extra_files[@]}")"
  export GORAPE_EXTRA_COMPOSE_FILES
fi

if [[ "$do_pull" == "1" && "$mode" == "hub" ]]; then
  info "Pulling $image_ref ..."
  compose pull server
fi

if [[ "$all_services" == "1" ]]; then
  services=()
elif [[ "$server_only" == "1" ]]; then
  services=(server)
else
  services=(postgres redis keycloak server)
fi

up_args=(up -d)
if [[ "$mode" == "local" && "$do_build" == "1" ]]; then
  up_args+=(--build)
fi
if [[ ${#services[@]} -gt 0 ]]; then
  up_args+=("${services[@]}")
  info "Starting: ${services[*]}"
else
  info "Starting: all services"
fi
compose "${up_args[@]}"

if [[ "$do_wait" == "1" ]]; then
  wait_for_http "Gorape API" "http://localhost:8000/health" 120
  if [[ "$server_only" != "1" ]]; then
    wait_for_http "Keycloak realm" \
      "http://localhost:8080/realms/gorape/.well-known/openid-configuration" 180
  fi
fi

cat <<EOF

${C_BOLD}Gorape is running${C_RESET}
  API             http://localhost:8000
  Health          http://localhost:8000/health
  Keycloak        http://localhost:8080/realms/gorape
  Admin console   http://localhost:8080/admin (admin / admin)

Next:
  ./scripts/keycloak-allow-redirect.sh    # allow the Flutter redirect URI
  ./scripts/run-android.sh                # build/run on a connected device

EOF
