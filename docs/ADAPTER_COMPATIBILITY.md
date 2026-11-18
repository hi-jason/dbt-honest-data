# Adapter compatibility and reproduction

The core synthetic suite is exercised against:

| Environment | Versions |
| --- | --- |
| dbt Core | 1.12.6 |
| DuckDB | dbt-duckdb 1.11.1, DuckDB 2.0.0 |
| PostgreSQL | dbt-postgres 1.11.0, PostgreSQL 16 |

The v1.1.7 test inventory expects 38 passing assertions, 44 deliberately corrupted assertions returning FAIL (not ERROR), and 22 Python harness tests. Current execution results are in the [Core dbt contracts CI](https://github.com/hi-jason/dbt-honest-data/actions/workflows/core-tests.yml). Each adapter is tested independently.

## Reproduce with invented data

Install the matching dbt Core and adapter versions in a disposable Python environment. From the repository root, use `bash integration_tests/run.sh`. The runner changes to its own working directory, verifies its reviewed source definitions, installs the local package, builds invented models, and validates both clean and corrupt cases.

For PostgreSQL set `HONEST_DATA_TARGET=postgres` and `HONEST_DATA_PG_PASSWORD` for a temporary local PostgreSQL 16 instance with database `synthetic_fixture`, user `synthetic_tester`, port `5432`. Never point the synthetic profile at a real application database.

## Support boundaries

These two adapter combinations are the only ones verified. The macros use `varchar`, metadata introspection, timestamps, and database-specific expression behavior; Snowflake, BigQuery, Redshift, Fabric and other adapters require their own execution and performance verification. Tests that compare keys need compatible native SQL types and a documented business key grain. Pattern-based privacy checks are only secondary alarms, not a privacy certification.

---

[← README](../README.md) · [Case study](when-clean-data-lies.md) · [All docs](README.md)
