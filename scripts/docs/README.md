# Documentation developer tools

- `link_gf_ids.py` resolves gf-app IDs (`GF-0xxxx`) and backend IDs (`GF-1xxxx`)
  to source-comment lines in the corresponding GitHub repositories. Backend
  lookup defaults to the sibling `../gorape` checkout or `GORAPE_BACKEND_DIR`.
  The GitHub Pages workflow clones the backend before checking links. The tool
  skips fenced code blocks (including Mermaid diagrams), refreshes stale line
  numbers, and supports `--check`. It processes both language trees:

  ```bash
  python3 scripts/docs/link_gf_ids.py
  python3 scripts/docs/link_gf_ids.py --check
  ```

  Use `--ref BRANCH_OR_TAG` for gf-app and `--backend-ref BRANCH_OR_TAG` for
  Gorape to link to other refs.
- `build-book.sh` builds the separate English and Japanese books to
  `build/docs-site/en/` and `build/docs-site/jp/`, then creates the language
  landing page at `build/docs-site/index.html`. Each book has its own
  `book.toml` under `docs/en/` and `docs/jp/`; shared Mermaid assets live in
  `docs/shared/`. Install `mdbook` and `mdbook-mermaid` before building.
