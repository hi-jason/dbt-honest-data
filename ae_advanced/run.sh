#!/usr/bin/env bash
# Synthetic materializations only; no production credentials.
set -euo pipefail
cd "$(dirname "$0")"
export DBT_PROFILES_DIR="$PWD"
DBT_BIN="${DBT:-dbt}"

# Explicit safety refusal before *any* database writes.
case "${AE_ADVANCED_ADAPTER:-duckdb}" in
  duckdb) ;;
  postgres)
    if [ "${PGDATABASE:-}" != "ae_quality_synthetic" ] || [ "${PGUSER:-}" != "synthetic_only" ]; then
      echo "REFUSED: advanced project only allows a synthetic PostgreSQL DB/user" >&2; exit 2
    fi
    case "${PGHOST:-localhost}" in
      localhost|127.0.0.1) ;;
      *) echo "REFUSED: advanced project must use localhost PostgreSQL" >&2; exit 2 ;;
    esac ;;
  *) echo "REFUSED: unsupported adapter" >&2; exit 2 ;;
esac

python3 -m unittest -q test_verify.py
rm -rf target
mkdir -p target

# Static history and reconciliation cases.
"$DBT_BIN" run --select ledger_source mart_correct mart_bad_offsets mart_wrong_total history_good history_overlap history_two_current history_duplicate_version history_null_identity

# First capture: full-refresh creates exactly two initial incrementally tracked rows.
"$DBT_BIN" run --select source_events --vars '{"batch": 1}'
"$DBT_BIN" run --full-refresh --select inc_orders bad_inc_append --vars '{"batch": 1}'
"$DBT_BIN" ls --resource-type test --select "path:tests/initial" --output json > target/initial.jsonl
rm -f target/run_results.json
"$DBT_BIN" test --select "path:tests/initial"
python3 verify.py initial target/initial.jsonl target/run_results.json

# Next capture corrects 101 with an older *event date* but newer update time.
"$DBT_BIN" run --select source_events --vars '{"batch": 2}'
"$DBT_BIN" run --select inc_orders bad_inc_append --vars '{"batch": 2}'

# Replay the same batch. The lookback window re-reads 101, 102 and 103, so
# this proves the upsert replaces re-read rows instead of duplicating them.
"$DBT_BIN" run --select inc_orders bad_inc_append --vars '{"batch": 2}'

"$DBT_BIN" ls --resource-type test --select "path:tests/positive" --output json > target/positive.jsonl
"$DBT_BIN" ls --resource-type test --select "path:tests/negative" --output json > target/negative.jsonl
"$DBT_BIN" ls --resource-type test --output json > target/all_tests.jsonl
python3 verify.py inventory target/all_tests.jsonl target/initial.jsonl target/positive.jsonl target/negative.jsonl

rm -f target/run_results.json
"$DBT_BIN" test --select "path:tests/positive"
python3 verify.py positive target/positive.jsonl target/run_results.json

rm -f target/run_results.json
set +e
"$DBT_BIN" test --select "path:tests/negative"
exit_code=$?
set -e
if [ "$exit_code" -eq 0 ]; then
  echo "FAIL-CLOSED: intentionally bad advanced cases unexpectedly passed" >&2; exit 1
fi
python3 verify.py negative target/negative.jsonl target/run_results.json
echo "Advanced synthetic quality tests verified."
