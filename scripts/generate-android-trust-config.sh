#!/usr/bin/env bash
# Generate the Android Key Attestation trust-anchor configuration used by the
# Gorape backend container.
#
# The Google endpoint returns a JSON array of PEM certificates. Gorape's
# Android verifier accepts one or more PEM roots through
# Application.Server.Attestation.android_trust_anchors.
#
# Output (git-ignored):
#   config/generated/android-attestation-roots.pem
#   config/generated/server.yaml
#
# The generated server.yaml is a copy of the backend's etc/server.yaml.docker
# with only the android_trust_anchors line replaced. The backend checkout is
# never modified.

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

GOOGLE_ROOT_URL="https://android.googleapis.com/attestation/root"

usage() {
  cat <<EOF
Usage: ./scripts/generate-android-trust-config.sh [options]

Options:
  --source URL|FILE   Trust-anchor source (default: $GOOGLE_ROOT_URL)
  --output DIR        Output directory (default: config/generated)
  --config FILE       Backend config template
                      (default: \$GORAPE_BACKEND_DIR/etc/server.yaml.docker)
  -h, --help          Show this help
EOF
}

source_ref="$GOOGLE_ROOT_URL"
output_dir="$GENERATED_DIR"
template=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      [[ $# -ge 2 ]] || die "--source requires a value"
      source_ref="$2"
      shift
      ;;
    --output)
      [[ $# -ge 2 ]] || die "--output requires a value"
      output_dir="$2"
      shift
      ;;
    --config)
      [[ $# -ge 2 ]] || die "--config requires a value"
      template="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

require_command python3
require_backend
require_command curl

template="${template:-$BACKEND_DIR/etc/server.yaml.docker}"
[[ -f "$template" ]] || die "Backend config template not found: $template"

mkdir -p "$output_dir"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

raw_file="$work_dir/roots.json"
info "Fetching Android trust anchors: $source_ref"
if [[ "$source_ref" =~ ^https?:// ]]; then
  curl -fsSL --retry 3 --max-time 30 "$source_ref" -o "$raw_file"
else
  [[ -f "$source_ref" ]] || die "Source file not found: $source_ref"
  cp "$source_ref" "$raw_file"
fi

python3 - "$raw_file" "$output_dir/android-attestation-roots.pem" <<'PY'
import json
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
destination = pathlib.Path(sys.argv[2])

try:
    decoded = json.loads(source)
except json.JSONDecodeError:
    decoded = source

if isinstance(decoded, list):
    certificates = [str(item) for item in decoded]
elif isinstance(decoded, str):
    certificates = [decoded]
elif isinstance(decoded, dict) and "certificates" in decoded:
    certificates = [str(item) for item in decoded["certificates"]]
else:
    raise SystemExit("Unsupported trust-anchor document: expected PEM text or a JSON array of PEM strings")

normalized = []
for certificate in certificates:
    certificate = certificate.strip()
    if "-----BEGIN CERTIFICATE-----" not in certificate:
        raise SystemExit("Trust-anchor entries must contain PEM certificates")
    if "-----END CERTIFICATE-----" not in certificate:
        raise SystemExit("Malformed PEM certificate: missing END marker")
    normalized.append(certificate)

if not normalized:
    raise SystemExit("No certificates found in the trust-anchor document")

destination.write_text("\n".join(normalized) + "\n", encoding="utf-8")
print(f"Wrote {len(normalized)} certificate(s) to {destination}")
PY

if command -v openssl >/dev/null 2>&1; then
  python3 - "$output_dir/android-attestation-roots.pem" "$work_dir" <<'PY' >"$work_dir/manifest.txt"
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
out_dir = pathlib.Path(sys.argv[2])
blocks = []
current = []
for line in text.splitlines():
    if line.startswith("-----BEGIN CERTIFICATE-----"):
        current = [line]
    elif current:
        current.append(line)
        if line.startswith("-----END CERTIFICATE-----"):
            blocks.append("\n".join(current) + "\n")
            current = []
for index, block in enumerate(blocks, start=1):
    path = out_dir / f"cert-{index}.pem"
    path.write_text(block, encoding="utf-8")
    print(path)
PY

  if [[ ! -s "$work_dir/manifest.txt" ]]; then
    die "Could not split the trust-anchor bundle into individual certificates"
  fi

  while IFS= read -r certificate_file; do
    subject="$(openssl x509 -in "$certificate_file" -noout -subject 2>/dev/null)" ||
      die "Certificate is not a valid X.509 certificate: $certificate_file"
    fingerprint="$(openssl x509 -in "$certificate_file" -noout -fingerprint -sha256 2>/dev/null)"
    ok "$subject"
    printf '    %s\n' "$fingerprint"
  done <"$work_dir/manifest.txt"
else
  warn "openssl not found; skipped certificate validation"
fi

server_config="$output_dir/server.yaml"
info "Generating $server_config from $template"
python3 - "$template" "$server_config" <<'PY'
import pathlib
import re
import sys

template = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])
text = template.read_text(encoding="utf-8")

anchor = "/app/etc/android/android-attestation-roots.pem"
pattern = re.compile(r"(?m)^(?P<indent>[ \t]*)attestation:\s*\{[^}]*\}\s*$")

match = pattern.search(text)
if not match:
    raise SystemExit(
        "Could not find an inline 'attestation: {android_trust_anchors: []}' entry "
        f"in {template}. Adjust the generator for the new config layout."
    )

replacement = f'{match.group("indent")}attestation: {{android_trust_anchors: ["{anchor}"]}}'
text = text[: match.start()] + replacement + text[match.end() :]
destination.write_text(text, encoding="utf-8")
print(f"Set Android trust anchor to {anchor}")
PY

if ! grep -q "/app/etc/android/android-attestation-roots.pem" "$server_config"; then
  die "Generated config does not contain the expected trust-anchor mount path"
fi

cat <<EOF

${C_BOLD}Android trust-anchor configuration ready${C_RESET}
  Roots:  $output_dir/android-attestation-roots.pem
  Config: $server_config

Restart the backend with the generated configuration:
  ./scripts/gorape-up.sh --android-attestation

Then confirm the verifier is active (requires a signed-in access token):
  GET http://localhost:8000/v1/projects/{projectId}/attestation/capabilities
  {"verifiers":{"android":"implemented",...}}

Note: /app/etc/android is the path inside the server container. The Compose
override mounts the generated PEM there.
EOF
