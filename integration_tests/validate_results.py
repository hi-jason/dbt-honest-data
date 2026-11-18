#!/usr/bin/env python3
"""Fail-closed dbt selection + result validation; negative 'error' is NOT a pass."""
import argparse
import json
import sys
from collections import Counter
from pathlib import Path

class ValidationError(Exception):
    pass

def read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (FileNotFoundError, ValueError, OSError) as exc:
        raise ValidationError(f"missing or invalid JSON {path}: {type(exc).__name__}") from exc

def read_selection(path):
    try:
        lines = Path(path).read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise ValidationError(f"cannot read selection {path}") from exc
    nodes = []
    for line in lines:
        if not line.lstrip().startswith("{"):
            continue
        try:
            n = json.loads(line)
        except ValueError as exc:
            raise ValidationError("dbt ls emitted invalid JSON") from exc
        if n.get("resource_type") == "test":
            if not n.get("unique_id"):
                raise ValidationError("dbt ls emitted test without unique_id")
            nodes.append(n)
    if not nodes:
        raise ValidationError("empty test selection")
    ids = [n["unique_id"] for n in nodes]
    if len(set(ids)) != len(ids):
        raise ValidationError("duplicate selected test IDs")
    return nodes

def check_selection(nodes, catalog):
    if len(nodes) != catalog["count"]:
        raise ValidationError(f"selected {len(nodes)} tests, expected {catalog['count']}")
    expected = set(catalog["macros"])
    counts = Counter()
    for n in nodes:
        meta = n.get("test_metadata") or {}
        macro = meta.get("name", "") if isinstance(meta, dict) else ""
        if macro not in expected:
            name = n.get("name", "")
            matches = [x for x in expected if name.startswith(x + "_")
                       or name.startswith("honest_data_" + x + "_")]
            if len(matches) != 1:
                raise ValidationError(f"unknown test macro for {n['unique_id']}: {name}")
            macro = matches[0]
        counts[macro] += 1
    if counts != Counter(catalog["macros"]):
        raise ValidationError(f"wrong macro inventory: {dict(counts)}; expected {catalog['macros']}")

    # Per-macro counts are insufficient. Replacing a missing test with
    # another test of the SAME macro keeps both counts and status green.
    # The checked-in per-fixture manifest is an independent coverage lock.
    expected_cases = catalog.get("cases")
    if not isinstance(expected_cases, list) or len(expected_cases) != catalog["count"]:
        raise ValidationError("fixture case inventory is missing or incomplete")
    candidates = {}
    for item in expected_cases:
        if not isinstance(item, str) or item.count("|") != 1:
            raise ValidationError("malformed fixture identity in catalog")
        model, macro = item.split("|")
        if not model or macro not in expected:
            raise ValidationError("invalid model or macro in fixture identity")
        candidates.setdefault(macro, set()).add(model)
    measured_cases = Counter()
    for node in nodes:
        metadata = node.get("test_metadata") or {}
        macro = metadata.get("name", "") if isinstance(metadata, dict) else ""
        if macro not in expected:
            macro_matches = [m for m in expected
                             if node.get("name", "").startswith(m + "_")
                             or node.get("name", "").startswith("honest_data_" + m + "_")]
            if len(macro_matches) != 1:
                raise ValidationError(f"unrecognized fixture macro: {node.get('unique_id')}")
            macro = macro_matches[0]
        name = node.get("name", "")
        models = sorted(candidates[macro], key=len, reverse=True)
        matching = [
            model for model in models
            if name == f"{macro}_{model}"
            or name.startswith(f"{macro}_{model}_")
            or name == f"honest_data_{macro}_{model}"
            or name.startswith(f"honest_data_{macro}_{model}_")
        ]
        if not matching and name in candidates[macro]:
            # Singular tests are named directly by their filename.
            matching = [name]
        if not matching:
            # dbt supplies attached_node on some adapters/versions.
            attached = node.get("attached_node")
            if attached:
                candidate = str(attached).rsplit(".", 1)[-1]
                matching = [candidate] if candidate in candidates[macro] else []
        if not matching:
            raise ValidationError(
                f"selected test has no anchored fixture identity: {node.get('unique_id')}")
        # Longest prefix first disambiguates e.g. jobs vs jobs_labelled.
        measured_cases[f"{matching[0]}|{macro}"] += 1
    if measured_cases != Counter(expected_cases):
        missing = sorted((Counter(expected_cases) - measured_cases).elements())
        extra = sorted((measured_cases - Counter(expected_cases)).elements())
        raise ValidationError(f"fixture identity drift: missing={missing}, extra={extra}")

def check_results(path, nodes, expected_status):
    data = read_json(path)
    rows = data.get("results") if isinstance(data, dict) else None
    if not isinstance(rows, list):
        raise ValidationError("run_results.json has no results array")
    seen = [r.get("unique_id") for r in rows]
    if None in seen or len(set(seen)) != len(seen):
        raise ValidationError("run_results contains duplicate/missing IDs")
    selected = {n["unique_id"] for n in nodes}
    if set(seen) != selected:
        raise ValidationError(f"results differ from selected IDs: missing={sorted(selected-set(seen))}, extra={sorted(set(seen)-selected)}")
    unexpected = [(r.get("unique_id"), r.get("status")) for r in rows
                  if r.get("status") != expected_status]
    if unexpected:
        raise ValidationError(f"expected status {expected_status}, saw {unexpected}")
    return len(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("honest", "dishonest"), required=True)
    parser.add_argument("--selection", required=True)
    parser.add_argument("--results", required=True)
    parser.add_argument("--catalog", default=str(Path(__file__).with_name("expected_case_catalog.json")))
    args = parser.parse_args()
    try:
        nodes = read_selection(args.selection)
        check_selection(nodes, read_json(args.catalog)[args.phase])
        n = check_results(args.results, nodes, "pass" if args.phase == "honest" else "fail")
    except (ValidationError, KeyError, OSError) as exc:
        print(f"FAIL-CLOSED {args.phase}: {exc}", file=sys.stderr)
        return 1
    print(f"{args.phase}: all {n} selected tests returned required status")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
