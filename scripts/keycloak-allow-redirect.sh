#!/usr/bin/env bash
# Add gf-app redirect URIs to the Gorape Keycloak client.
#
# Existing redirect URIs (including the CLI callback
# http://127.0.0.1:8400/callback) are preserved. The operation is idempotent.
#
# The Flutter apps use Authorization Code + PKCE (S256) and a native custom
# scheme. Keycloak only accepts a redirect URI that is registered on the client.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-gorape}"
KEYCLOAK_CLIENT_ID="${KEYCLOAK_CLIENT_ID:-gorape-client}"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
DEFAULT_REDIRECT_URI="com.gorapeflutter.gfapp:/oauth2redirect"

usage() {
  cat <<EOF
Usage: ./scripts/keycloak-allow-redirect.sh [options]

Options:
  --uri URI             Redirect URI to add. May be repeated.
                        Default: $DEFAULT_REDIRECT_URI
  --keycloak-url URL    Keycloak base URL (default: $KEYCLOAK_URL)
  --realm NAME          Realm (default: $KEYCLOAK_REALM)
  --client-id ID        Client (default: $KEYCLOAK_CLIENT_ID)
  --show                Print the current client redirect URIs and exit
  -h, --help            Show this help

Environment:
  KEYCLOAK_ADMIN, KEYCLOAK_ADMIN_PASSWORD   Admin credentials
EOF
}

redirect_uris=()
show_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uri)
      [[ $# -ge 2 ]] || die "--uri requires a value"
      redirect_uris+=("$2")
      shift
      ;;
    --keycloak-url)
      [[ $# -ge 2 ]] || die "--keycloak-url requires a value"
      KEYCLOAK_URL="${2%/}"
      shift
      ;;
    --realm)
      [[ $# -ge 2 ]] || die "--realm requires a value"
      KEYCLOAK_REALM="$2"
      shift
      ;;
    --client-id)
      [[ $# -ge 2 ]] || die "--client-id requires a value"
      KEYCLOAK_CLIENT_ID="$2"
      shift
      ;;
    --show) show_only=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

if [[ ${#redirect_uris[@]} -eq 0 ]]; then
  redirect_uris=("$DEFAULT_REDIRECT_URI")
fi

require_command curl
require_command python3

info "Requesting an admin token from $KEYCLOAK_URL"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

token_response="$(
  curl -fsS --max-time 15 \
    -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'client_id=admin-cli' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode "username=$KEYCLOAK_ADMIN" \
    --data-urlencode "password=$KEYCLOAK_ADMIN_PASSWORD"
)" || die "Could not obtain a Keycloak admin token. Is $KEYCLOAK_URL reachable?"

token="$(
  TOKEN_JSON="$token_response" python3 -c \
    'import json, os; print(json.loads(os.environ["TOKEN_JSON"]).get("access_token", ""))'
)"
[[ -n "$token" ]] || die "Keycloak did not return an access token (check admin credentials)."

auth_header="Authorization: Bearer $token"

info "Reading client '$KEYCLOAK_CLIENT_ID' in realm '$KEYCLOAK_REALM'"
curl -fsS --max-time 15 \
  -H "$auth_header" \
  "$KEYCLOAK_URL/admin/realms/$KEYCLOAK_REALM/clients?clientId=$KEYCLOAK_CLIENT_ID" \
  -o "$work_dir/clients.json" ||
  die "Could not list clients. Is the realm '$KEYCLOAK_REALM' present?"

client_id="$(
  python3 - "$work_dir/clients.json" "$KEYCLOAK_CLIENT_ID" <<'PY'
import json
import sys

clients = json.load(open(sys.argv[1], encoding="utf-8"))
for client in clients:
    if client.get("clientId") == sys.argv[2]:
        print(client["id"])
        break
PY
)"
[[ -n "$client_id" ]] || die "Client '$KEYCLOAK_CLIENT_ID' was not found in realm '$KEYCLOAK_REALM'."

curl -fsS --max-time 15 \
  -H "$auth_header" \
  "$KEYCLOAK_URL/admin/realms/$KEYCLOAK_REALM/clients/$client_id" \
  -o "$work_dir/client.json" ||
  die "Could not read client '$KEYCLOAK_CLIENT_ID'."

if [[ "$show_only" == "1" ]]; then
  python3 - "$work_dir/client.json" <<'PY'
import json
import sys

client = json.load(open(sys.argv[1], encoding="utf-8"))
print(json.dumps({
    "clientId": client.get("clientId"),
    "publicClient": client.get("publicClient"),
    "redirectUris": client.get("redirectUris", []),
    "webOrigins": client.get("webOrigins", []),
    "attributes": client.get("attributes", {}),
}, indent=2))
PY
  exit 0
fi

python3 - "$work_dir/client.json" "$work_dir/updated.json" "$work_dir/changed" "${redirect_uris[@]}" <<'PY'
import json
import sys

source, destination, status_path, *requested = sys.argv[1:]
client = json.load(open(source, encoding="utf-8"))

existing = list(client.get("redirectUris") or [])
merged = list(existing)
for uri in requested:
    if uri not in merged:
        merged.append(uri)

attributes = dict(client.get("attributes") or {})
attributes["pkce.code.challenge.method"] = "S256"
# "+" means reuse redirectUris for post-logout redirects, preserving the CLI.
attributes.setdefault("post.logout.redirect.uris", "+")

changed = merged != existing or attributes != (client.get("attributes") or {})
client["redirectUris"] = merged
client["attributes"] = attributes
json.dump(client, open(destination, "w", encoding="utf-8"), indent=2)
open(status_path, "w", encoding="utf-8").write("1" if changed else "0")

print("Existing redirect URIs:")
for uri in existing:
    print(f"  - {uri}")
added = [uri for uri in merged if uri not in existing]
if added:
    print("Adding redirect URIs:")
    for uri in added:
        print(f"  + {uri}")
elif not changed:
    print("No redirect URI changes needed.")
PY

if [[ "$(cat "$work_dir/changed")" != "1" ]]; then
  ok "Keycloak client is already configured."
  exit 0
fi

info "Updating client '$KEYCLOAK_CLIENT_ID'"
curl -fsS --max-time 15 \
  -X PUT \
  -H "$auth_header" \
  -H 'Content-Type: application/json' \
  --data-binary "@$work_dir/updated.json" \
  "$KEYCLOAK_URL/admin/realms/$KEYCLOAK_REALM/clients/$client_id" ||
  die "Keycloak rejected the client update."

ok "Redirect URIs updated"
python3 - "$work_dir/updated.json" <<'PY'
import json
import sys

client = json.load(open(sys.argv[1], encoding="utf-8"))
print(json.dumps({
    "clientId": client.get("clientId"),
    "redirectUris": client.get("redirectUris", []),
    "pkce": client.get("attributes", {}).get("pkce.code.challenge.method"),
    "postLogoutRedirectUris": client.get("attributes", {}).get("post.logout.redirect.uris"),
}, indent=2))
PY
