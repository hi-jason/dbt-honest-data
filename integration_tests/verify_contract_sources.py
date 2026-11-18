#!/usr/bin/env python3
"""Fail-closed integrity check for reviewed synthetic dbt contract declarations.

Git blob hashes lock argument-bearing schema YAML and standalone SQL tests.
This is a change-review tripwire, not a signature or protection from a
malicious change that also edits the checked-in manifest.
"""
import hashlib
import json
import re
import sys
from pathlib import Path


class SourceIntegrityError(Exception):
    pass


def git_blob_sha(data):
    """Git hashes a blob as sha1(b'blob ' + length + b'\\0' + data)."""
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def verify_sources(root, manifest_path=None):
    root = Path(root)
    manifest_path = Path(manifest_path) if manifest_path else root / "expected_contract_sources.json"
    try:
        catalog = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise SourceIntegrityError("missing or invalid source manifest") from exc
    expected = catalog.get("sources") if isinstance(catalog, dict) else None
    if not isinstance(expected, dict) or not expected:
        raise SourceIntegrityError("source manifest missing source map")
    if any(
        not isinstance(name, str) or not isinstance(blob, str)
        or not re.fullmatch(r"[0-9a-f]{40}", blob)
        or Path(name).is_absolute() or ".." in Path(name).parts
        for name, blob in expected.items()
    ):
        raise SourceIntegrityError("invalid source manifest entry")

    # New tests may not silently evade the lock. Only these two source
    # declaration formats are supported. Model data SQL is not covered.
    observed = set()
    for phase in ("honest", "dishonest"):
        observed.update(
            p.relative_to(root).as_posix()
            for p in (root / "models" / phase).rglob("*.yml")
        )
        observed.update(
            p.relative_to(root).as_posix()
            for p in (root / "models" / phase).rglob("*.yaml")
        )
        observed.update(
            p.relative_to(root).as_posix()
            for p in (root / "tests" / phase).rglob("*.sql")
        )
    expected_names = set(expected)
    if observed != expected_names:
        raise SourceIntegrityError(
            f"unreviewed contract source inventory: missing={sorted(expected_names-observed)}, "
            f"unexpected={sorted(observed-expected_names)}"
        )
    for name in sorted(expected):
        p = root / name
        if p.is_symlink() or not p.is_file():
            raise SourceIntegrityError(f"missing or symlinked source: {name}")
        try:
            actual = git_blob_sha(p.read_bytes())
        except OSError as exc:
            raise SourceIntegrityError(f"unreadable contract source: {name}") from exc
        if actual != expected[name]:
            raise SourceIntegrityError(f"changed contract source requires review: {name}")
    return len(observed)


def main():
    try:
        n = verify_sources(Path(__file__).resolve().parent)
    except SourceIntegrityError as exc:
        print(f"FAIL-CLOSED source lock: {exc}", file=sys.stderr)
        return 1
    print(f"Reviewed contract definitions unchanged ({n} source files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
