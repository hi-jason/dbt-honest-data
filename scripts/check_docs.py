#!/usr/bin/env python3
"""Offline repository-local Markdown link and fence validation.

No network, credentials, data warehouse, third-party packages or writes.
"""
from __future__ import annotations

from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
LINK = re.compile(r"!?\[[^\]\n]+\]\(([^)\n]+)\)")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(?:[^\n]*)$")
SKIP_DIRS = {".git", ".venv", "venv", "dbt_packages", "target", "logs", "__pycache__"}


def check_document(path: Path) -> tuple[int, list[str]]:
    count = 0
    errors: list[str] = []
    fence_char = None
    fence_width = 0
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        marker = FENCE.match(line)
        if marker:
            run = marker.group(1)
            if fence_char is None:
                fence_char, fence_width = run[0], len(run)
            elif run[0] == fence_char and len(run) >= fence_width:
                fence_char, fence_width = None, 0
            continue
        if fence_char is not None:
            continue
        for found in LINK.finditer(line):
            raw = found.group(1).strip()
            # Optional Markdown title follows the target, separated by space.
            target = raw.split(maxsplit=1)[0].strip("<>")
            if not target or target.startswith("#"):
                continue
            if urlsplit(target).scheme or target.startswith("//"):
                continue
            relative = unquote(target.split("#", 1)[0].split("?", 1)[0])
            if not relative:
                continue
            count += 1
            resolved = (path.parent / relative).resolve()
            if resolved != ROOT and ROOT not in resolved.parents:
                errors.append(f"{path.relative_to(ROOT)}:{line_no}: link escapes repository: {target}")
            elif not resolved.exists():
                errors.append(f"{path.relative_to(ROOT)}:{line_no}: missing link target: {target}")
    if fence_char is not None:
        errors.append(f"{path.relative_to(ROOT)}: unclosed {fence_char * fence_width} code fence")
    return count, errors


def main() -> int:
    files = sorted(p for p in ROOT.rglob("*.md") if not SKIP_DIRS.intersection(p.relative_to(ROOT).parts))
    total = 0
    errors: list[str] = []
    for path in files:
        count, file_errors = check_document(path)
        total += count
        errors.extend(file_errors)
    for error in errors:
        print(f"ERROR: {error}")
    print(f"Checked {len(files)} Markdown documents and {total} local links; errors: {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
