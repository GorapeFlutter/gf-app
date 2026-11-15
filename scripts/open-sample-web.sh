#!/usr/bin/env bash
# Open the sample Vue 3 app in Chrome with local.gorapeflutter.github.io mapped
# to 127.0.0.1 so WebAuthn RP ID "gorapeflutter.github.io" is accepted natively
# without modifying /etc/hosts or breaking GitHub Pages Digital Asset Links.

set -euo pipefail

URL="${1:-https://local.gorapeflutter.github.io:5174}"
PROFILE_DIR="${TMPDIR:-/tmp}/gorape-sample-chrome-profile"
mkdir -p "$PROFILE_DIR"

if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --user-data-dir="$PROFILE_DIR" \
    --host-resolver-rules="MAP local.gorapeflutter.github.io 127.0.0.1" \
    --ignore-certificate-errors \
    "$URL" >/dev/null 2>&1 &
  echo "Opened $URL in Google Chrome (local.gorapeflutter.github.io -> 127.0.0.1)"
else
  echo "Google Chrome not found at /Applications/Google Chrome.app."
  echo "Add '127.0.0.1 local.gorapeflutter.github.io' to /etc/hosts and open: $URL"
fi
