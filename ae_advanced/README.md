# Advanced example project

*Part of [dbt-honest-data](../README.md) · [Case study](../docs/when-clean-data-lies.md) · [All docs](../docs/README.md)*

This **isolated, synthetic-only** self-contained example dbt project expands
the [basic example project](../ae_starter/README.md). All names, dates, amounts and
identifiers are invented. It connects to no real database and does not
modify the core honest-data package.

## What the project tests

**Incremental state and replay.** Source batch 1 produces orders 101 and 102.
Batch 2 changes order 101 from 100.00 to 120.00 (with an *older* event
timestamp but a *newer* source update timestamp), retains 102, and adds 103
in two versions because it changed twice between runs. The corrected
incremental `delete+insert` upsert re-reads a three-day lookback window and
keeps only the latest version of each order inside a batch, so it ends with
exactly three orders. Replaying batch 2 re-reads all three again, which proves
re-read rows are replaced rather than duplicated. The deliberately wrong
`append` model creates duplicate identities and **must fail**. This shows
SCD1/overwrite behavior, not the retention of historical versions.

**Changes over time (SCD2-style interval checks).** A static, invented
history table stores earlier and current versions of the same account. It
must have half-open, non-overlapping `[valid_from,valid_to)` intervals, valid
bounds, exactly one current row per account and a nonempty population.
Deliberately invalid fixtures cover overlapping intervals, multiple current
records, duplicate version IDs, and missing identity keys. Each must fail by
assertion. These static examples do not exercise dbt's actual snapshot
materialization or any hard-delete policy. Legitimate historical gaps are not failed by default.

**Compare business totals with the individual records.** A three-order ledger totals 130.00.
A correct mart passes both aggregate and per-key checks. A corrupted mart
adds 10.00 to one order and subtracts 10.00 from another: its grand total
still passes, but its *key-level* reconciliation must fail. Another corrupt
mart has an incorrect total and must fail the aggregate check. These examples show why a real project must verify the ledger's authority and reconcile amounts at the declared business grain.

## Run in an isolated environment

Requires **dbt-core 1.12.6**, and **dbt-duckdb 1.11.1** or
**dbt-postgres 1.11.0**. No community package is installed here.

```bash
cd ae_advanced
export AE_ADVANCED_ADAPTER=duckdb
bash run.sh
```

For a disposable local PostgreSQL 16 database, set
`AE_ADVANCED_ADAPTER=postgres`, `PGHOST=localhost`,
`PGUSER=synthetic_only`, `PGDATABASE=ae_quality_synthetic`,
and the disposable DB password. The runner rejects remote PostgreSQL hosts, unknown
adapters, and PostgreSQL users or database names outside its synthetic-only settings. These checks reduce accidental misconfiguration but do not replace database isolation or least-privilege access. Do not supply production credentials.

## Expected smoke-test results

- **1** initial-phase passing data assertion;
- **9** final-phase passing data assertions;
- **7** deliberately corrupt final data assertions that must return dbt
  **FAIL** (not an execution ERROR or unexpected PASS);
- **8** Python validator self-tests;
- an exact reviewed test-name roster and full 17-node inventory.

The runner builds static history/finance models, materializes batch 1,
validates batch 1, materializes batch 2, replays batch 2, and then validates
all final assertions. CI runs the complete sequence independently in
DuckDB and ephemeral PostgreSQL.

## Limitations and future choices

Review [the decision register](../docs/AE_EXCLUSIONS_AND_DECISIONS.md)
before automatically adding packages. This project **does not** assert
snapshot hard deletes, interval continuity without business definition,
source SLA freshness, authoritative ledger correctness, production-scale performance,
PII safety or adapters other than the two exercised here.

The sample load decides what is new from the latest update time it has
already loaded, minus a three-day lookback (`lookback_days`). The lookback
catches updates that land a little late, and the in-batch dedupe keeps one
version per order. It is still incomplete: an update more than three days
behind the watermark is missed, two versions with the same `updated_at` are
ordered arbitrarily, and hard deletes are not handled. Actual projects need a
lookback sized to the source's real delays, an ingestion timestamp or
per-key change tracking, and a delete policy. Passing the replay scenario
does not establish correctness for every possible source update sequence.

## Sources

- [dbt incremental models](https://docs.getdbt.com/docs/build/incremental-models)
- [dbt incremental strategies](https://docs.getdbt.com/docs/build/incremental-strategy?version=1.12)
- [dbt snapshots and hard-deletes](https://docs.getdbt.com/docs/build/snapshots?version=1.12)
- [dbt unit test overrides](https://docs.getdbt.com/reference/resource-properties/unit-test-overrides?version=1.12)
