#!/usr/bin/env bash
# Generate a local CA and a TLS server certificate for the Gorape dev server.
# Private keys are written only under config/generated/tls (Git-ignored).

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/generate-local-tls.sh [options]

Options:
  --host HOST   Add a DNS name or IP address to the server certificate SAN.
                May be repeated. gorapeflutter.site, api.gorapeflutter.site,
                idp.gorapeflutter.site, app.gorapeflutter.site,
                local.gorapeflutter.site, localhost, 127.0.0.1 and ::1 are
                always added.
  --force       Replace the generated local TLS files if they already exist.
  -h, --help    Show this help.

Output (Git-ignored): config/generated/tls/{ca.crt,ca.key,server.crt,server.key}
The CA private key and server private key are local development secrets.
EOF
}

require_command openssl
require_command python3
require_command git

output_dir="$APP_ROOT/config/generated/tls"
[[ ! -L "$APP_ROOT/config" && ! -L "$APP_ROOT/config/generated" && ! -L "$output_dir" ]] ||
  die "Refusing to write TLS keys through a symlink: $output_dir"
git -C "$APP_ROOT" check-ignore -q "$output_dir/server.key" ||
  die "TLS output is not Git-ignored. Refusing to write private keys: $output_dir"
hosts=(
  gorapeflutter.site
  api.gorapeflutter.site
  idp.gorapeflutter.site
  app.gorapeflutter.site
  local.gorapeflutter.site
  localhost
  127.0.0.1
  ::1
)
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      [[ $# -ge 2 ]] || die "--host requires a DNS name or IP address"
      hosts+=("$2")
      shift
      ;;
    --force) force=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

if [[ "$force" != "1" ]] && {
  [[ -e "$output_dir/ca.key" ]] || [[ -e "$output_dir/ca.crt" ]] ||
  [[ -e "$output_dir/server.key" ]] || [[ -e "$output_dir/server.crt" ]]
}; then
  die "TLS files already exist in $output_dir; inspect them or pass --force to replace them."
fi

mkdir -p "$output_dir"
chmod 700 "$output_dir"
if [[ "$force" == "1" ]]; then
  rm -f "$output_dir/ca.key" "$output_dir/ca.crt" \
    "$output_dir/server.key" "$output_dir/server.crt" "$output_dir/ca.srl"
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
openssl_config="$work_dir/server-ext.cnf"

python3 - "$openssl_config" "${hosts[@]}" <<'PY'
import ipaddress
import pathlib
import re
import sys

destination = pathlib.Path(sys.argv[1])
hosts = list(dict.fromkeys(sys.argv[2:]))
entries = []
dns_index = 0
ip_index = 0

for host in hosts:
    if not host or any(char in host for char in "\r\n,/"):
        raise SystemExit(f"Invalid certificate host: {host!r}")
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        normalized = host.rstrip(".").lower()
        if len(normalized) > 253 or not all(
            re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label)
            for label in normalized.split(".")
        ):
            raise SystemExit(f"Invalid DNS name: {host!r}")
        dns_index += 1
        entries.append(f"DNS.{dns_index} = {normalized}")
    else:
        ip_index += 1
        entries.append(f"IP.{ip_index} = {address.compressed}")

destination.write_text(
    "[server_cert]\n"
    "basicConstraints = critical,CA:FALSE\n"
    "keyUsage = critical,digitalSignature,keyEncipherment\n"
    "extendedKeyUsage = serverAuth\n"
    "subjectKeyIdentifier = hash\n"
    "authorityKeyIdentifier = keyid,issuer\n"
    "subjectAltName = @alt_names\n\n"
    "[alt_names]\n" + "\n".join(entries) + "\n",
    encoding="utf-8",
)
PY

umask 077
info "Generating local development CA and server certificate"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 \
  -out "$output_dir/ca.key" >/dev/null 2>&1
openssl req -x509 -new -sha256 -days 3650 \
  -key "$output_dir/ca.key" \
  -subj "/CN=Gorape Local Development CA" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash" \
  -out "$output_dir/ca.crt"

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$output_dir/server.key" >/dev/null 2>&1
openssl req -new -sha256 -key "$output_dir/server.key" \
  -subj "/CN=api.gorapeflutter.site" -out "$work_dir/server.csr"
openssl x509 -req -sha256 -days 397 \
  -in "$work_dir/server.csr" \
  -CA "$output_dir/ca.crt" -CAkey "$output_dir/ca.key" \
  -CAcreateserial -extfile "$openssl_config" -extensions server_cert \
  -out "$output_dir/server.crt"

chmod 600 "$output_dir/ca.key" "$output_dir/server.key"
chmod 644 "$output_dir/ca.crt" "$output_dir/server.crt"
rm -f "$output_dir/ca.srl"

openssl verify -CAfile "$output_dir/ca.crt" "$output_dir/server.crt" >/dev/null
ok "Server certificate ready: $output_dir/server.crt"
ok "Private keys are mode 600 and remain in the Git-ignored config/generated/tls directory"
printf 'CA fingerprint: '
openssl x509 -in "$output_dir/ca.crt" -noout -fingerprint -sha256
printf '\nStart Gorape with HTTPS enabled:\n  ./scripts/gorape-up.sh --https\n'
