#!/usr/bin/env python3
"""Reject dbt data tests that quietly escape the positive/negative smoke phases."""
import json
import sys
from pathlib import Path


class InventoryError(Exception):
    pass


def read_ids(path):
    try:
        lines = Path(path).read_text(encoding="utf-8").splitlines()
        records = [json.loads(line) for line in lines if line.lstrip().startswith("{")]
    except (OSError, ValueError) as exc:
        raise InventoryError("missing/invalid dbt ls selection") from exc
    ids = [x.get("unique_id") for x in records if x.get("resource_type") == "test"]
    if not ids or None in ids or len(ids) != len(set(ids)):
        raise InventoryError("empty, missing or repeated data test IDs")
    return set(ids)


def audit(all_path, positive_path, negative_path):
    all_ids = read_ids(all_path)
    positives = read_ids(positive_path)
    negatives = read_ids(negative_path)
    if len(all_ids) != 23 or len(positives) != 16 or len(negatives) != 7:
        raise InventoryError("data test count changed: review all fixtures and expected cases")
    if positives & negatives:
        raise InventoryError("same test appears in positive and negative phase")
    if all_ids != positives | negatives:
        raise InventoryError(
            f"data tests not fully graded: unknown={sorted(all_ids - positives - negatives)} "
            f"missing={sorted(positives | negatives - all_ids)}"
        )
    return len(all_ids)


def main():
    if len(sys.argv) != 4:
        print("usage: audit_inventory.py ALL POSITIVE NEGATIVE", file=sys.stderr)
        return 2
    try:
        n = audit(*sys.argv[1:])
    except InventoryError as exc:
        print(f"FAIL-CLOSED inventory: {exc}", file=sys.stderr)
        return 1
    print(f"PASS inventory: all {n} data test nodes graded once")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
