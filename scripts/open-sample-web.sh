#!/usr/bin/env bash
# Open the sample Vue 3 app in Chrome at https://app.gorapeflutter.site:5174.
# *.gorapeflutter.site resolves to 127.0.0.1 via DNS so WebAuthn RP ID
# "gorapeflutter.site" is accepted natively without modifying /etc/hosts.
# Trust config/generated/tls/ca.crt in the OS keychain for local TLS verification.

set -euo pipefail

URL="${1:-https://app.gorapeflutter.site:5174}"
PROFILE_DIR="${TMPDIR:-/tmp}/gorape-sample-chrome-profile"
mkdir -p "$PROFILE_DIR"

if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --user-data-dir="$PROFILE_DIR" \
    "$URL" >/dev/null 2>&1 &
  echo "Opened $URL in Google Chrome (ensure config/generated/tls/ca.crt is trusted by the OS)"
else
  echo "Google Chrome not found at /Applications/Google Chrome.app."
  echo "Open in a browser that trusts config/generated/tls/ca.crt: $URL"
fi
