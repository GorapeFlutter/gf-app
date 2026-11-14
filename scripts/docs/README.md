# Documentation developer tools

- `link_gf_ids.py` resolves GF IDs to source-comment lines and links them to the
  canonical `https://github.com/GorapeFlutter/gf-app/` `main` branch. It skips
  fenced code blocks (including Mermaid diagrams), refreshes stale line numbers,
  and supports `--check`:

  ```bash
  python3 scripts/docs/link_gf_ids.py
  python3 scripts/docs/link_gf_ids.py --check
  ```

  Use `--ref BRANCH_OR_TAG` to link to another GitHub ref.
- `build-book.sh` builds the mdBook into the ignored `build/mdbook/` directory.
  The root `book.toml` configures mdBook; install `mdbook`, `mdbook-tabs`, and
  `mdbook-mermaid` before building.
