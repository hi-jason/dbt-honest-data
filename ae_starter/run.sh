#!/usr/bin/env bash
# Synthetic-only executable examples. Never use production database settings.
set -euo pipefail
cd "$(dirname "$0")"
export DBT_PROFILES_DIR="$PWD"
DBT_BIN="${DBT:-dbt}"

# Safety gate: this demonstration may write *only* to its local, disposable DB.
# A future project must intentionally design its own disposable environment.
case "${AE_STARTER_ADAPTER:-duckdb}" in
  duckdb) ;;
  postgres)
    if [ "${PGDATABASE:-}" != "ae_quality_synthetic" ] || [ "${PGUSER:-}" != "synthetic_only" ]; then
      echo "REFUSED: postgres starter requires synthetic_only in ae_quality_synthetic" >&2
      exit 2
    fi
    case "${PGHOST:-localhost}" in
      localhost|127.0.0.1) ;;
      *) echo "REFUSED: postgres starter only supports a localhost disposable instance" >&2; exit 2 ;;
    esac
    ;;
  *) echo "REFUSED: unknown starter adapter" >&2; exit 2 ;;
esac

python3 -m unittest -q test_validate_results.py test_audit_inventory.py test_safety_gate.py
rm -rf target
mkdir -p target
"$DBT_BIN" deps
"$DBT_BIN" run

# All positive DATA assertions must pass, with an exact selected-result set.
"$DBT_BIN" ls --resource-type test --select "path:models/honest" "path:tests/honest" --exclude "test_type:unit" --indirect-selection=cautious --output json > target/positive_selection.jsonl
rm -f target/run_results.json
"$DBT_BIN" test --select "path:models/honest" "path:tests/honest" --exclude "test_type:unit" --indirect-selection=cautious
python3 validate_results.py positive target/positive_selection.jsonl target/run_results.json

# Every corrupt assertion must fail because it found DATA corruption, not an ERROR.
"$DBT_BIN" ls --resource-type test --select "tag:ae_starter_negative" --output json > target/negative_selection.jsonl
"$DBT_BIN" ls --resource-type test --output json > target/all_data_selection.jsonl
python3 audit_inventory.py target/all_data_selection.jsonl target/positive_selection.jsonl target/negative_selection.jsonl
rm -f target/run_results.json
set +e
"$DBT_BIN" test --select "tag:ae_starter_negative"
negative_exit=$?
set -e
if [ "$negative_exit" -eq 0 ]; then
  echo "FAIL-CLOSED: corrupted fixtures returned a successful dbt exit" >&2
  exit 1
fi
python3 validate_results.py negative target/negative_selection.jsonl target/run_results.json

# Native SQL unit tests (independent of materialized data test results).
"$DBT_BIN" ls --resource-type unit_test --select "test_type:unit" --output json > target/unit_selection.jsonl
rm -f target/run_results.json
"$DBT_BIN" test --select "test_type:unit"
python3 validate_results.py unit target/unit_selection.jsonl target/run_results.json
echo "Starter smoke complete: native + dbt-utils + unit + negative fixtures verified."
