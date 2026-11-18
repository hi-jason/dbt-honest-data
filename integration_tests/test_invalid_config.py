#!/usr/bin/env python3
"""Synthetic invalid-config smoke test.

A deliberately invalid configuration should fail for the expected reason,
not because of a missing model, a stale artifact, an import error or an
unrelated SQL problem. Unlike negative DATA fixtures, compiler errors are
acceptable here only when the targeted diagnostic matches.
"""
import json
import os
import subprocess
import sys


def run():
    dbt = os.environ.get("DBT", "dbt")
    cases = [
        (
            "unknown feature switch",
            "partner_rows_switch_on",
            {"partner_feed_enabled_on": "NOT_A_BOOLEAN"},
            "honest_data: boolean option kill_switch_holds.switch_on must be",
        ),
    ]
    for label, selection, variables, diagnostic in cases:
        command = [dbt, "compile", "--select", selection,
                   "--vars", json.dumps(variables)]
        outcome = subprocess.run(command, capture_output=True, text=True,
                                 check=False, timeout=120)
        output = outcome.stdout + "\n" + outcome.stderr
        if outcome.returncode == 0:
            print(f"FAIL: invalid-config case {label} compiled successfully",
                  file=sys.stderr)
            return 1
        if diagnostic not in output:
            # Deliberately avoid emitting full compiler output in logs;
            # it may contain SQL literal arguments in real deployments.
            print(f"FAIL: invalid-config case {label} failed for a different reason "
                  f"(exit {outcome.returncode})", file=sys.stderr)
            return 1
        print(f"PASS: invalid-config case {label} rejected as intended")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
