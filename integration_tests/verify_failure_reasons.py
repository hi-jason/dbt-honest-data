#!/usr/bin/env python3
"""Inspect stored failing rows in synthetic test databases.

This is intentionally limited to local disposable DuckDB/PostgreSQL fixtures.
It verifies *failure labels*, not only that dbt reported status='fail'.
"""
from __future__ import annotations

from collections import Counter
import json
import os
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
EXPECTED = {
    ("filter_or_future_in_scope", "not_in_the_future"):
        Counter({"dated in the future": 1}),
    ("export_from_the_future", "not_in_the_future"):
        Counter({"dated in the future": 1}),
    ("source_badly_split", "partitions_into"):
        Counter({"input key is missing from all parts": 1,
                 "key appears in multiple parts": 1}),
    ("identity_null", "one_row_per_identity"):
        Counter({"row has no usable exact identity": 1}),
    ("latest_drops_and_invents", "every_row_accounted_for"):
        Counter({"in the source, missing here": 1,
                 "here, but not in the source": 1,
                 "more than once here": 1}),
}


def selected_test(nodes, model, macro):
    names = []
    for node in nodes:
        name = node.get("name", "")
        # dbt versions expose package-qualified metadata differently; match
        # the fully anchored model + macro prefix, never a loose substring.
        prefixes = (macro + "_" + model, "honest_data_" + macro + "_" + model)
        if any(name == p or name.startswith(p + "_") for p in prefixes):
            names.append(node["unique_id"])
    if len(names) != 1:
        raise ValueError("Expected exactly one test for " + model + "|" + macro
                         + "; observed " + str(len(names)))
    return names[0]


def relation_identifier(name):
    if not isinstance(name, str) or not re.fullmatch(r'["A-Za-z0-9_.]+', name):
        raise ValueError("unsafe or missing stored-failures relation")
    return name


def connect():
    target = os.getenv("HONEST_DATA_TARGET", "dev")
    if target == "dev":
        import duckdb
        path = HERE / "target" / "honest_data_integration.duckdb"
        if not path.is_file():
            raise ValueError("disposable DuckDB file is missing")
        return duckdb.connect(str(path), read_only=True)
    if target == "postgres":
        import psycopg2
        return psycopg2.connect(
            host="127.0.0.1", port=5432, user="synthetic_tester",
            password=os.getenv("HONEST_DATA_PG_PASSWORD", "synthetic_ci_only"),
            dbname="synthetic_fixture", connect_timeout=5)
    raise ValueError("unsupported adapter; refusing non-disposable database access")


def main():
    selection = []
    for line in (HERE / "target" / "dishonest_selection.jsonl").read_text().splitlines():
        if line.lstrip().startswith("{"):
            node = json.loads(line)
            if node.get("resource_type") == "test":
                selection.append(node)
    results = json.loads((HERE / "target" / "run_results.json").read_text())
    indexed = {r["unique_id"]: r for r in results["results"]}
    if len(indexed) != len(results["results"]):
        raise ValueError("duplicate result IDs")
    con = connect()
    try:
        for (model, macro), expected in EXPECTED.items():
            node_id = selected_test(selection, model, macro)
            result = indexed.get(node_id)
            if result is None or result.get("status") != "fail":
                raise ValueError("missing assertion FAIL for " + model + "|" + macro)
            if result.get("failures") != sum(expected.values()):
                raise ValueError("wrong number of failing rows for " + model + "|" + macro)
            relation = relation_identifier(result.get("relation_name"))
            if hasattr(con, "cursor"):
                cursor = con.cursor()
                try:
                    cursor.execute("select failure from " + relation)
                    actual = Counter(row[0] for row in cursor.fetchall())
                finally:
                    cursor.close()
            else:
                actual = Counter(row[0] for row in con.execute("select failure from " + relation).fetchall())
            if actual != expected:
                raise ValueError("wrong failure reason(s) for " + model + "|" + macro
                                 + ": got " + str(actual))
            print(model + "|" + macro + ": expected failing rows and reasons confirmed")
        print("Checked exact failure reasons for " + str(len(EXPECTED)) + " focused fixtures")
    finally:
        con.close()


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, ImportError) as exc:
        print("FAIL-CLOSED failure-reason audit: " + str(exc), file=sys.stderr)
        raise SystemExit(1)
