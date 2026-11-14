# Documentation developer tools

- `link_gf_ids.py` resolves GF IDs to source-comment lines and links them to the
  canonical `https://github.com/GorapeFlutter/gf-app/` `main` branch. It skips
  fenced code blocks (including Mermaid diagrams), refreshes stale line numbers,
  and supports `--check`. It processes both language trees:

  ```bash
  python3 scripts/docs/link_gf_ids.py
  python3 scripts/docs/link_gf_ids.py --check
  ```

  Use `--ref BRANCH_OR_TAG` to link to another GitHub ref.
- `build-book.sh` builds the separate English and Japanese books to
  `build/docs-site/en/` and `build/docs-site/jp/`, then creates the language
  landing page at `build/docs-site/index.html`. Each book has its own
  `book.toml` under `docs/en/` and `docs/jp/`; shared Mermaid assets live in
  `docs/shared/`. Install `mdbook` and `mdbook-mermaid` before building.
