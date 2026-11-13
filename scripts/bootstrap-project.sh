#!/usr/bin/env bash
# Bootstrap a Gorape project with an initial admin using the latest schema.
#
# The gorape-admin CLI currently references legacy table names (project_domains).
# This helper applies the current schema directly through psql.
#
# Usage:
#   ./scripts/bootstrap-project.sh --slug demo --name "Demo Project" \
#     --admin-subject <keycloak-user-id> [--issuer http://localhost:8080/realms/gorape] [--realm gorape]

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap-project.sh [options]

Options:
  --slug SLUG              Project slug (required)
  --name NAME              Project display name (required)
  --admin-subject SUBJECT  Keycloak user id (sub) of the initial admin (required)
  --issuer ISSUER          OIDC issuer (default: http://localhost:8080/realms/gorape)
  --realm REALM            Keycloak realm (default: gorape)
  -h, --help               Show this help
EOF
}

slug=""
name=""
subject=""
issuer="http://localhost:8080/realms/gorape"
realm="gorape"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug) slug="$2"; shift 2 ;;
    --name) name="$2"; shift 2 ;;
    --admin-subject) subject="$2"; shift 2 ;;
    --issuer) issuer="$2"; shift 2 ;;
    --realm) realm="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$slug" ]] || die "--slug is required"
[[ -n "$name" ]] || die "--name is required"
[[ -n "$subject" ]] || die "--admin-subject is required"

require_command docker

info "Bootstrapping project $slug ($name) with admin $subject"

docker exec -i gorape-postgres psql -U user -d gorape <<SQL
INSERT INTO projects (slug, name, issuer, realm)
VALUES ('$slug', '$name', '$issuer', '$realm')
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
SELECT id, '$issuer', '$subject'
FROM projects WHERE slug = '$slug'
ON CONFLICT (issuer, subject) DO NOTHING;

INSERT INTO role_bindings (project_id, principal_id, scope, role_key)
SELECT p.project_id, p.id, 'project', 'admin'
FROM principals p
WHERE p.subject = '$subject'
ON CONFLICT DO NOTHING;

SELECT id, slug, name FROM projects WHERE slug = '$slug';
SQL

ok "Project $slug bootstrapped"
