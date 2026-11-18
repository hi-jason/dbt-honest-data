#!/usr/bin/env python3
"""Strict dbt 1.12 synthetic phase validator. ERROR != intended data FAIL."""
import argparse
import json
import sys
from pathlib import Path

EXPECTED = {
    "initial": {"assert_phase_one_state"},
    "positive": {
        "history_no_overlap", "history_one_current", "history_nonempty",
        "history_unique_versions",
        "revenue_by_key_correct", "revenue_total_correct",
        "revenue_total_bad_offsets_still_passes",
        "incremental_final_state", "incremental_no_duplicate",
    },
    "negative": {
        "history_overlap_detected", "history_double_current_detected",
        "history_duplicate_version_detected", "history_missing_identity_detected",
        "revenue_key_offsets_detected", "revenue_total_change_detected",
        "incremental_append_duplicate_detected",
    },
}


class VerificationError(Exception):
    pass


def selection(path):
    try:
        lines = Path(path).read_text(encoding="utf-8").splitlines()
        rows = [json.loads(x) for x in lines if x.lstrip().startswith("{")]
    except (OSError, ValueError) as exc:
        raise VerificationError("selection missing or malformed") from exc
    nodes = [n for n in rows if n.get("resource_type") == "test"]
    ids = [n.get("unique_id") for n in nodes]
    names = [n.get("name") for n in nodes]
    if not nodes or None in ids or None in names or len(set(ids)) != len(ids):
        raise VerificationError("missing or duplicate selected node")
    return nodes


def verify_phase(phase, selection_file, results_file):
    nodes = selection(selection_file)
    actual = [n["name"] for n in nodes]
    if len(actual) != len(EXPECTED[phase]) or set(actual) != EXPECTED[phase]:
        raise VerificationError(f"unreviewed {phase} test inventory: {actual}")
    try:
        results = json.loads(Path(results_file).read_text(encoding="utf-8"))["results"]
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise VerificationError("result artifact missing or malformed") from exc
    expected_ids = {x["unique_id"] for x in nodes}
    actual_ids = [x.get("unique_id") for x in results]
    if len(actual_ids) != len(expected_ids) or set(actual_ids) != expected_ids:
        raise VerificationError(f"{phase} missing/extra/duplicate result")
    status = "fail" if phase == "negative" else "pass"
    unexpected = [(x.get("unique_id"), x.get("status")) for x in results
                  if x.get("status") != status]
    if unexpected:
        raise VerificationError(f"{phase}: expected status {status}, saw {unexpected}")
    return len(actual)


def verify_inventory(all_file, phase_files):
    full = selection(all_file)
    all_ids = {n["unique_id"] for n in full}
    all_names = {n["name"] for n in full}
    expected_names = set().union(*EXPECTED.values())
    if all_names != expected_names or len(full) != len(expected_names):
        raise VerificationError("unregistered or missing test in global dbt inventory")
    seen = set()
    for f in phase_files:
        for node in selection(f):
            uid = node["unique_id"]
            if uid in seen:
                raise VerificationError("test selected in multiple phases")
            seen.add(uid)
    if seen != all_ids:
        raise VerificationError(f"ungraded test selection: {sorted(all_ids-seen)}")
    return len(all_ids)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("phase", choices=("initial", "positive", "negative", "inventory"))
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    try:
        if args.phase == "inventory":
            if len(args.files) != 4:
                raise VerificationError("inventory requires ALL INITIAL POSITIVE NEGATIVE")
            n = verify_inventory(args.files[0], args.files[1:])
        else:
            if len(args.files) != 2:
                raise VerificationError("phase requires selection and run_results")
            n = verify_phase(args.phase, *args.files)
    except VerificationError as exc:
        print(f"FAIL-CLOSED: {exc}", file=sys.stderr)
        return 1
    print(f"PASS {args.phase}: {n} verified tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
