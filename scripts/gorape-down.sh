#!/usr/bin/env bash
# Stop the Gorape Docker environment used by gf-app.
#
# Examples:
#   ./scripts/gorape-down.sh            # stop/remove containers, keep volumes
#   ./scripts/gorape-down.sh --server   # only the API server container
#   ./scripts/gorape-down.sh --volumes  # DESTRUCTIVE: also delete volumes

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/gorape-down.sh [options]

Options:
  --server     Remove only the API server container (keeps postgres/keycloak).
  --volumes    Also remove named volumes. Deletes the database and Keycloak data.
  -h, --help   Show this help.
EOF
}

server_only=0
remove_volumes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) server_only=1 ;;
    --volumes) remove_volumes=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

require_command docker
require_backend

if [[ "$server_only" == "1" ]]; then
  info "Stopping the Gorape server container"
  compose stop server || true
  compose rm -f -v server
  ok "Server container removed. Dependencies were left running."
  exit 0
fi

down_args=(down --remove-orphans)
if [[ "$remove_volumes" == "1" ]]; then
  warn "Removing volumes: the Gorape database and Keycloak realm import state will be lost."
  down_args+=(--volumes)
fi

info "Stopping the Gorape environment"
compose "${down_args[@]}"
ok "Gorape environment stopped"
