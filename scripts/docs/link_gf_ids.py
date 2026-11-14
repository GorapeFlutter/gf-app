#!/usr/bin/env python3
"""Link GF IDs outside fenced diagrams to their source comment on GitHub."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


ID_RE = re.compile(r"GF-\d{5}")
FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
INLINE_CODE_RE = re.compile(r"(`+)([^`]*?)\1")
GITHUB_LINK_RE = re.compile(r"\[(GF-\d{5})\]\(https://github\.com/[^)]+\)")

FLOW_SOURCE = {
    "GF-00001": "lib/app.dart",
    "GF-00002": "lib/controller/auth.dart",
    "GF-00003": "lib/repository/gorape.dart",
    "GF-00004": "lib/controller/project.dart",
    "GF-00005": "lib/usecase/device.dart",
    "GF-00006": "lib/usecase/device.dart",
    "GF-00007": "lib/usecase/device.dart",
    "GF-00008": "lib/controller/group.dart",
    "GF-00009": "lib/controller/role.dart",
    "GF-00010": "lib/controller/role.dart",
    "GF-00011": "lib/controller/connection.dart",
    "GF-00012": "lib/controller/policy.dart",
    "GF-00013": "lib/controller/language.dart",
}


def github_root(repo: Path) -> str:
    remote = subprocess.check_output(
        ["git", "remote", "get-url", "origin"], cwd=repo, text=True
    ).strip()
    if remote.startswith("git@github.com:"):
        remote = "https://github.com/" + remote.removeprefix("git@github.com:")
    elif remote.startswith("ssh://git@github.com/"):
        remote = "https://github.com/" + remote.removeprefix("ssh://git@github.com/")
    return remote.removesuffix(".git").rstrip("/")


def source_comment_locations(repo: Path) -> dict[str, list[tuple[str, int]]]:
    locations: dict[str, list[tuple[str, int]]] = defaultdict(list)
    source_files = sorted((repo / "lib").rglob("*.dart"))
    source_files.extend(
        sorted((repo / "android/app/src/main").rglob("*.kt"))
    )

    for relative in source_files:
        path = relative
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            for match in ID_RE.finditer(line):
                prefix = line[: match.start()]
                is_comment = (
                    (prefix.rfind("//") >= 0)
                    or (prefix.rfind("/*") >= 0)
                    or line.lstrip().startswith("*")
                )
                if is_comment:
                    locations[match.group()].append(
                        (relative.relative_to(repo).as_posix(), line_number)
                    )

    return locations


def make_link(
    identifier: str,
    locations: dict[str, list[tuple[str, int]]],
    github: str,
    ref: str,
) -> str:
    candidates = locations.get(identifier, [])
    if not candidates:
        raise KeyError(f"No source comment found for {identifier}")

    preferred_path = FLOW_SOURCE.get(identifier)
    location = next(
        (item for item in candidates if item[0] == preferred_path), candidates[0]
    )
    source_path, line_number = location
    url = f"{github}/blob/{ref}/{source_path}#L{line_number}"
    return f"[{identifier}]({url})"


def link_line(
    line: str,
    locations: dict[str, list[tuple[str, int]]],
    github: str,
    ref: str,
) -> tuple[str, int]:
    replacements = 0

    def link_plain_text(text: str) -> str:
        nonlocal replacements

        def refresh_link(match: re.Match[str]) -> str:
            nonlocal replacements
            current = match.group(0)
            updated = make_link(match.group(1), locations, github, ref)
            if updated != current:
                replacements += 1
            return updated

        text = GITHUB_LINK_RE.sub(refresh_link, text)

        def replace_plain(match: re.Match[str]) -> str:
            nonlocal replacements
            identifier = match.group()
            start, end = match.span()
            if (start > 0 and text[start - 1] == "[") or text[end : end + 2] == "](":
                return identifier
            replacements += 1
            return make_link(identifier, locations, github, ref)

        return ID_RE.sub(replace_plain, text)

    output: list[str] = []
    cursor = 0
    for match in INLINE_CODE_RE.finditer(line):
        output.append(link_plain_text(line[cursor : match.start()]))
        code_content = match.group(2)
        if ID_RE.fullmatch(code_content):
            replacements += 1
            output.append(make_link(code_content, locations, github, ref))
        else:
            output.append(match.group(0))
        cursor = match.end()
    output.append(link_plain_text(line[cursor:]))
    return "".join(output), replacements


def link_document(
    text: str,
    locations: dict[str, list[tuple[str, int]]],
    github: str,
    ref: str,
) -> tuple[str, int]:
    output: list[str] = []
    active_fence: tuple[str, int] | None = None
    replacements = 0

    for line in text.splitlines(keepends=True):
        fence = FENCE_RE.match(line)
        if active_fence is not None:
            output.append(line)
            if fence and fence.group(1)[0] == active_fence[0]:
                if len(fence.group(1)) >= active_fence[1]:
                    active_fence = None
            continue

        if fence:
            active_fence = (fence.group(1)[0], len(fence.group(1)))
            output.append(line)
            continue

        linked, count = link_line(line, locations, github, ref)
        output.append(linked)
        replacements += count

    return "".join(output), replacements


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--ref",
        default="main",
        help="GitHub branch, tag, or commit to link to (default: main)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report documents that need link updates without editing them",
    )
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    docs = repo / "docs/_locales"
    github = github_root(repo)
    locations = source_comment_locations(repo)
    markdown_files = sorted(docs.rglob("*.md"))
    changed: list[str] = []
    missing: set[str] = set()

    for path in markdown_files:
        original = path.read_text()
        try:
            linked, count = link_document(original, locations, github, args.ref)
        except KeyError as error:
            missing.add(str(error))
            continue

        if linked == original:
            continue
        relative = path.relative_to(repo).as_posix()
        changed.append(f"{relative}: {count} ID links")
        if not args.check:
            path.write_text(linked)

    if missing:
        print("Missing source IDs:", file=sys.stderr)
        print("\n".join(sorted(missing)), file=sys.stderr)
        return 1

    if args.check:
        if changed:
            print("Documents need GF ID links:")
            print("\n".join(changed))
            return 1
        print("GF ID links are up to date.")
        return 0

    if changed:
        print("Updated GF ID links:")
        print("\n".join(changed))
    else:
        print("No GF ID links needed updating.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
