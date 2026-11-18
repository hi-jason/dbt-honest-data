#!/usr/bin/env bash
# Fail closed on stale, missing, partially selected or errored dbt tests.
set -euo pipefail
cd "$(dirname "$0")"
export DBT_PROFILES_DIR="$PWD"
DBT_CMD="dbt"
if [ -n "$(printenv DBT 2>/dev/null || true)" ]; then DBT_CMD="$(printenv DBT)"; fi

python3 -m unittest -q test_validate_results.py test_verify_contract_sources.py
python3 verify_contract_sources.py
"$DBT_CMD" deps
"$DBT_CMD" run

mkdir -p target
"$DBT_CMD" ls --resource-type test --select "path:models/honest" "path:tests/honest" --output json > target/honest_selection.jsonl
rm -f target/run_results.json
"$DBT_CMD" test --select "path:models/honest" "path:tests/honest"
python3 validate_results.py --phase honest --selection target/honest_selection.jsonl --results target/run_results.json

"$DBT_CMD" ls --resource-type test --select "path:models/dishonest" "path:tests/dishonest" --output json > target/dishonest_selection.jsonl
rm -f target/run_results.json
set +e
"$DBT_CMD" test --store-failures --select "path:models/dishonest" "path:tests/dishonest"
negative_exit=$?
set -e
if [ "$negative_exit" -eq 0 ]; then
    echo "FAIL-CLOSED: dbt reported success for deliberately broken fixtures" >&2
    exit 1
fi
python3 validate_results.py --phase dishonest --selection target/dishonest_selection.jsonl --results target/run_results.json
python3 verify_failure_reasons.py
python3 test_invalid_config.py
echo "All selected synthetic fixtures and invalid configurations behaved as expected."
