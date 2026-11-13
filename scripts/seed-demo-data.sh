#!/usr/bin/env bash
# Seed demo users for local development.
#
# Creates user01..user50 in Keycloak (password: Password123!) and registers them in
# the single "demo" project with rotating roles (admin/editor/viewer). The
# backend expects one project per OIDC issuer, so all users share the demo
# project. Idempotent: existing users and bindings are reused.
#
# Usage:
#   ./scripts/seed-demo-data.sh

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

KEYCLOAK_BASE="${KEYCLOAK_BASE:-http://localhost:8080}"
REALM="${KEYCLOAK_REALM:-gorape}"
ISSUER="$KEYCLOAK_BASE/realms/$REALM"
USER_COUNT="${SEED_USER_COUNT:-50}"
PASSWORD="${SEED_PASSWORD:-Password123!}"

require_command curl
require_command docker
require_command python3

info "Fetching Keycloak admin token"
TOKEN=$(curl -s -X POST "$KEYCLOAK_BASE/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

editor_subject=""
viewer_subject=""

for i in $(seq 1 "$USER_COUNT"); do
  username=$(printf "user%02d" "$i")
  user_id=$(curl -s "$KEYCLOAK_BASE/admin/realms/$REALM/users?username=$username" \
    -H "Authorization: Bearer $TOKEN" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")
  if [[ -z "$user_id" ]]; then
    info "Creating user $username"
    curl -s -X POST "$KEYCLOAK_BASE/admin/realms/$REALM/users" \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d "{\"username\":\"$username\",\"enabled\":true,\"email\":\"$username@gf.local\"}" >/dev/null
    user_id=$(curl -s "$KEYCLOAK_BASE/admin/realms/$REALM/users?username=$username" \
      -H "Authorization: Bearer $TOKEN" \
      | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
  fi
  curl -s -X PUT "$KEYCLOAK_BASE/admin/realms/$REALM/users/$user_id/reset-password" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"type\":\"password\",\"value\":\"$PASSWORD\",\"temporary\":false}" >/dev/null

  if (( i <= 17 )); then role="admin"; elif (( i <= 34 )); then role="editor"; else role="viewer"; fi
  if (( i == 18 )); then editor_subject="$user_id"; fi
  if (( i == 35 )); then viewer_subject="$user_id"; fi
  kc_role="gorape-$role"
  role_id=$(curl -s "$KEYCLOAK_BASE/admin/realms/$REALM/roles/$kc_role" \
    -H "Authorization: Bearer $TOKEN" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
  curl -s -X POST "$KEYCLOAK_BASE/admin/realms/$REALM/users/$user_id/role-mappings/realm" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "[{\"id\":\"$role_id\",\"name\":\"$kc_role\"}]" >/dev/null

  docker exec -i gorape-postgres psql -U user -d gorape <<SQL
INSERT INTO projects (slug, name, issuer, realm)
VALUES ('demo', 'Demo Project', '$ISSUER', '$REALM')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO role_definitions (project_id, key, name, permissions, keycloak_role, builtin)
SELECT p.id, r.key, r.name, r.permissions::jsonb, r.keycloak_role, true
FROM projects p
CROSS JOIN (VALUES
  ('viewer', 'viewer', '["project:read","group:read","device:read","attestation:read"]', 'gorape-viewer'),
  ('editor', 'editor', '["project:read","group:read","group:bind","device:read","device:register","device:verify","device:revoke","attestation:read"]', 'gorape-editor'),
  ('admin', 'admin', '["*"]', 'gorape-admin')
) AS r(key, name, permissions, keycloak_role)
ON CONFLICT (project_id, key) DO NOTHING;

INSERT INTO principals (project_id, issuer, subject)
SELECT id, '$ISSUER', '$user_id' FROM projects WHERE slug='demo'
ON CONFLICT (issuer, subject) DO NOTHING;

INSERT INTO role_bindings (project_id, principal_id, scope, role_key)
SELECT p.project_id, p.id, 'project', '$role'
FROM principals p WHERE p.subject='$user_id'
ON CONFLICT DO NOTHING;
SQL
done

docker exec -i gorape-postgres psql -U user -d gorape \
  -v editor_subject="$editor_subject" -v viewer_subject="$viewer_subject" <<'SQL'
INSERT INTO groups (project_id, slug, name)
SELECT p.id, 'group' || lpad(n::text, 3, '0'), 'Group ' || lpad(n::text, 3, '0')
FROM projects p CROSS JOIN generate_series(1, 100) AS group_seq(n)
WHERE p.slug = 'demo'
ON CONFLICT (project_id, slug) DO NOTHING;

INSERT INTO groups (project_id, slug, name)
SELECT id, 'demo-team', 'Demo Team' FROM projects WHERE slug = 'demo'
ON CONFLICT (project_id, slug) DO NOTHING;

INSERT INTO role_bindings (project_id, principal_id, scope, group_id, role_key)
SELECT p.id, principal.id, 'group', g.id, 'editor'
FROM projects p
JOIN groups g ON g.project_id = p.id AND g.slug = 'demo-team'
JOIN principals principal ON principal.project_id = p.id
  AND principal.subject = :'editor_subject'
WHERE p.slug = 'demo'
ON CONFLICT DO NOTHING;

INSERT INTO role_bindings (project_id, principal_id, scope, group_id, role_key)
SELECT p.id, principal.id, 'group', g.id, 'viewer'
FROM projects p
JOIN groups g ON g.project_id = p.id AND g.slug = 'demo-team'
JOIN principals principal ON principal.project_id = p.id
  AND principal.subject = :'viewer_subject'
WHERE p.slug = 'demo'
ON CONFLICT DO NOTHING;
SQL

ok "Seeded $USER_COUNT users, 101 groups, and project/group role bindings."
printf '  Login: userNN / %s (admin 01-17, editor 18-34, viewer 35-50)\n' "$PASSWORD"
