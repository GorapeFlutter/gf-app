#!/usr/bin/env bash
# Shared helpers for the gf-app development scripts.
#
# All scripts can be run from any working directory. Override the backend
# location with GORAPE_BACKEND_DIR when the repositories are not siblings.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="${GORAPE_BACKEND_DIR:-$APP_ROOT/../gorape}"
GENERATED_DIR="${GORAPE_GENERATED_DIR:-$APP_ROOT/config/generated}"

# Docker Compose files from the Gorape repository, in Makefile order.
GORAPE_COMPOSE_FILES=(
  "docker/network.yaml"
  "docker/postgres.yaml"
  "docker/pgadmin.yaml"
  "docker/redis.yaml"
  "docker/keycloak.yaml"
  "docker/server.yaml"
  "docker/swagger.yaml"
  "docker/godoc.yaml"
  "docker/localstack.yaml"
)

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=""
  C_BOLD=""
  C_BLUE=""
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
fi

info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '%sOK%s  %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!!%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() {
  printf '%sERROR%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_backend() {
  [[ -d "$BACKEND_DIR" ]] ||
    die "Gorape backend not found at $BACKEND_DIR. Set GORAPE_BACKEND_DIR."
  [[ -f "$BACKEND_DIR/docker/server.yaml" ]] ||
    die "$BACKEND_DIR does not look like the Gorape repository (docker/server.yaml missing)."
}

# compose <args...>
# Runs docker compose against the Gorape project with an optional extra file
# list appended through GORAPE_EXTRA_COMPOSE_FILES (newline separated).
compose() {
  require_backend
  local -a args=(
    docker compose
    --project-directory "$BACKEND_DIR"
  )
  local file
  for file in "${GORAPE_COMPOSE_FILES[@]}"; do
    args+=(-f "$BACKEND_DIR/$file")
  done
  if [[ -n "${GORAPE_EXTRA_COMPOSE_FILES:-}" ]]; then
    while IFS= read -r file; do
      [[ -n "$file" ]] && args+=(-f "$file")
    done <<<"$GORAPE_EXTRA_COMPOSE_FILES"
  fi
  "${args[@]}" "$@"
}

wait_for_http() {
  local label="$1"
  local url="$2"
  local timeout="${3:-90}"
  local deadline=$((SECONDS + timeout))
  info "Waiting for $label ($url) ..."
  until curl -fsS --max-time 3 "$url" >/dev/null 2>&1; do
    if ((SECONDS >= deadline)); then
      die "Timed out after ${timeout}s waiting for $label."
    fi
    sleep 2
  done
  ok "$label is ready"
}

adb_required() {
  require_command adb
  local devices
  devices="$(adb devices | awk 'NR>1 && $2 == "device" {print $1}')"
  [[ -n "$devices" ]] ||
    die "No Android device or emulator is connected. Start one and retry."
  printf '%s\n' "$devices"
}
