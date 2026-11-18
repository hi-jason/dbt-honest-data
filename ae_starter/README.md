# Basic example project

*Part of [dbt-honest-data](../README.md) · [Case study](../docs/when-clean-data-lies.md) · [All docs](../docs/README.md)*

This is a **separate, self-contained example dbt project**, designed to demonstrate the
standard native + community-package tests selected in the
[testing playbook](../docs/AE_QUALITY_PLAYBOOK.md). It has no connection to
any production database, and does not alter the dependency-free honest-data
package. Every row in this project is invented.

## What the starter demonstrates

- Native: `unique`, `not_null`, `accepted_values`, `relationships`.
- Community reuse: `dbt_utils.unique_combination_of_columns` and
  `dbt_utils.expression_is_true`, pinned to dbt-utils 1.4.1.
- Native SQL model unit tests: discounted amount, left join, missing parent,
  and null discount behavior.
- Empty-data protection: a standalone SQL test must fail when an expected group has no rows.
- Adversarial mutation cases: duplicates, orphan key, wrong amount, invalid
  state, null ID, duplicate composite grain and empty model.
- Result checker: a deliberately broken sample must produce a dbt assertion **FAIL**,
  never an execution ERROR, a skipped test, or an unexpected PASS.

Expected outcome: **16 valid data tests PASS**, **7 deliberately invalid data tests FAIL**, **2 native unit tests PASS**, and **19 Python harness and safety checks PASS** on each supported adapter. The runner verifies selected test IDs, reviewed test names, and expected counts for each phase. An inventory audit also rejects any data test left outside
both valid and corrupted phases.

## Run locally in a disposable environment

Prerequisites: a disposable Python environment with dbt-core 1.12.6 and
dbt-duckdb 1.11.1, or dbt-postgres 1.11.0 and a disposable PostgreSQL database.
Do not point this profile at a production database.

```bash
cd ae_starter
export AE_STARTER_ADAPTER=duckdb
bash run.sh
```

The isolated `packages.yml` installs a pinned dbt-utils version during
`dbt deps`. It makes no changes to the enclosing honest-data package.

For PostgreSQL, set `AE_STARTER_ADAPTER=postgres` and the `PGHOST`, `PGUSER`, `PGPASSWORD`, and `PGDATABASE` variables for a **disposable local database**, then run the same script. The runner rejects remote PostgreSQL hosts and database/user names other than `ae_quality_synthetic` and `synthetic_only`. CI uses temporary PostgreSQL 16 containers with synthetic-only credentials. Do not reuse these settings for production.

## Reuse in another project

Reuse the **approach**, not the sample data or hard-coded business thresholds.
Start with this project's verified models and YAML on the target adapter.
Replace the fictional models with project-specific models, define the grain and sources, identify legitimate
key/null relationships, and add only high-value tests with a clear response
owner. Maintain a small deliberately broken test project in CI, without
letting bad data enter production.

For high-risk provenance, source/derived key conservation or exact
partitions, evaluate honest-data's specialized contracts *after* these
baseline tests. Use audit-helper when reconciling migrations. A green
smoke suite here does not certify any new dataset or warehouse.

## Limitations and review notes

- Two adapters only; other warehouses may interpret SQL/types differently.
- Fixed-scale numeric unit expectations such as a PostgreSQL `NUMERIC(12,2)`
  result should be quoted as `'15.00'` in YAML if scale matters; an unquoted
  `15` passes on DuckDB but fails on PostgreSQL.
- dbt's default indirect selection can include relationship tests from an
  unintended fixture, because the test references a selected parent model.
  Use the cautious valid selector and explicit negative test tags in run.sh.
- A `unique` test cannot detect missing expected entities. A `relationships`
  test says nothing about whether its parent table is authoritative.
- This small harness also checks reviewed test identities and the complete
  23-test data inventory; a semantic argument change can still preserve a
  generated test name. Review definition diffs when extending the starter.
- An execution error does not count as a correctly detected invalid fixture. All fixtures are synthetic; do not extend them with sensitive values.
- No production-scale query benchmark, freshness SLA, privacy certification,
  incremental merge execution, or automatic dependency updates.
