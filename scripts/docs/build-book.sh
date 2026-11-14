#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"
DOCS_ROOT="$REPO_ROOT/docs"
OUTPUT_ROOT="$REPO_ROOT/build/docs-site"

mdbook build "$DOCS_ROOT/en" --dest-dir "$OUTPUT_ROOT/en" "$@"
mdbook build "$DOCS_ROOT/jp" --dest-dir "$OUTPUT_ROOT/jp" "$@"
mkdir -p "$OUTPUT_ROOT"
cp "$DOCS_ROOT/index.html" "$OUTPUT_ROOT/index.html"
touch "$OUTPUT_ROOT/.nojekyll"
