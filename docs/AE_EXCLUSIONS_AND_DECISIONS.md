# Decision register
## Why some checks are not part of the baseline

This is a **decision register** for choosing tests on a new analytics-engineering project. It distinguishes (A) a poor generic fit, (B) a deliberately deferred dependency/cost, (C) an important test that requires real business inputs, and (D) work not yet validated. Exclusion from the baseline does not imply that a test or package is ineffective. For context see [the pattern catalog](AE_TEST_PATTERN_CATALOG.md), and [the testing playbook](AE_QUALITY_PLAYBOOK.md).

The adoption rule is **failure hypothesis → smallest credible check → adverse synthetic case → operational owner**. More tests or packages are not inherently better. Every exception should include why, the revisit trigger, cost/false-confidence risk, and an owner in the new project.

| Considered item | Disposition | Why it is NOT included by default | When to reconsider |
|---|---|---|---|
| dbt-native `unique`, `not_null`, `accepted_values`, `relationships` | **Included** | Baseline grain and relational invariants; still do not prove expected population or semantic accuracy | Always consider on critical models; use non-vacuity checks |
| dbt-utils 1.4.1 | **Included in optional starter only** | Composite grain and expression checks avoid unnecessary custom SQL, but adding it to dependency-free honest-data would reduce portability | Install/pin in the *consumer* project when a listed macro solves a real hazard |
| All sixteen honest-data checks on every table | **Poor fit** | Source/metric/provenance contracts are not universal; indiscriminate use creates false alarms and expensive redundant scans | Pick only ones with an explicit failure scenario |
| Metaplane dbt-expectations fork | **Deferred optional dependency** | Many expectations overlap native/dbt-utils; broader compatibility/cost not benchmarked here; original calogica fork is not the maintained version | A justified gap needs a distinct expectation; validate fork/adapter/version first |
| Great Expectations runtime | **Poor default fit** | Duplicates much of a dbt-only testing runtime and adds an operational dependency | Non-dbt multi-system checks or existing organizational investment |
| Elementary / anomaly monitoring | **Deferred** | Needs history, alert ownership, expected seasonality, service operations and cost assessment; synthetic two-row tables offer no baseline | Daily/high-scale SLAs with human incident response and trend evidence |
| dbt-project-evaluator | **Deferred governance** | Evaluates project architecture rather than correctness; its v2 line requires dbt 2, while this starter uses dbt 1.12 | Larger multi-team DAG; verify a compatible v1.x release or upgrade |
| dbt-audit-helper | **Deferred until migration** | Migration comparisons are valuable when old/new relations exist; unnecessary additional dependency for a small synthetic project | Replatform, refactor or reconcile old and new production marts |
| Statistical distribution / anomaly thresholds | **Needs business data** | Any asserted band without baseline, segmentation and owner is an invented quality target; unstable data causes alert fatigue | Seasonal history, tolerance and response owner available |
| Source freshness and volume SLAs | **Needs real source & schedule** | Hard-coded timestamps in static samples give misleading freshness evidence; freshness is not completeness | Real ingestion source with load timestamp, operating schedule and expected partitions |
| Generic `not_in_the_future` on every date | **Poor fit** | Plans, forecasts, future effective dates can legitimately be in future | Only timestamps contractually limited to time already observed |
| Generic no-gap temporal/SCD assertion | **Poor fit** | Real histories can have legitimate gaps for deletion, inactive periods and backfill; one-current record is not always required | Business-owned continuous coverage policy and deletion semantics |
| True dbt snapshots | **Deferred from first starter** | Requires repeated stateful source captures, valid updated_at and explicit hard-delete policies; not equivalent to a static history interval check | Historical CDC/SCD2 use case; validate `timestamp` vs `check`, hard_deletes and adapter behavior |
| Incremental upserts and stateful replay | **Now covered in advanced example** | Stateful materializations should not be represented as proof from compile-only unit tests | Any real incremental project; benchmark actual merge and late arrivals |
| Highly optimized incremental microbatch / partition overwrite | **Deferred adapter-specific** | Warehouse-specific partitioning and memory/cost behavior; not portable to a two-engine teaching starter | At production scale, after a measured performance bottleneck |
| Stored test failure rows / raw matched values | **Not a default** | Failure artifacts can expose the same confidential data tests are meant to protect | Approved restricted diagnostic environment with retention/access policy |
| Pattern-based PII name/value tests as privacy certification | **Explicitly rejected** | Rename, encoding, unknown sensitive fields and false negatives bypass patterns | Use explicit export allowlist, permissions, independent data classification; use patterns only as tripwires |
| Snowflake, BigQuery, Redshift, Fabric compatibility | **Not yet validated** | Current CI only proves DuckDB and ephemeral PostgreSQL; metadata semantics and SQL change by adapter | A real project uses that adapter; run both good and corrupted fixtures there |
| Distributed orchestration, auto-remediation and alert service | **Deferred** | A test that pages the wrong person every day can be worse than a simple fail-closed CI gate | Operational owner, severity routing and incident runbook agreed |
| Large generative mutation framework / cross-table fuzzing | **Deferred effort** | Complexity and non-determinism may outstrip value of small reviewed fault cases | Stable contracts with risk budget and an observed defect class that small fixtures miss |

## What the first executable starter does not cover

That starter intentionally validated just one product/order grain, arithmetic, a relationship, and empty-population behavior. It **did not** validate state transitions, late-arriving records, replay/idempotence, historical intervals, cross-grain finance reconciliation, source freshness, privacy proof, adapter performance or a SCD2 snapshot lifecycle. The next isolated [advanced synthetic example](../ae_advanced/README.md) addresses **incremental replay, history interval guards and key-level metric reconciliation**. It still is not a production snapshot lifecycle test, source freshness SLA or warehouse benchmark.

## Deliberately distinct meanings of quality

- **Test passes**: a particular relation did not return disallowed rows at one moment.
- **Test exercised**: a corrupted example demonstrably produced the intended failure status, not a SQL error.
- **Test coverage**: selected guards cover named failure hypotheses, not all business reality.
- **Model contract**: types and constraints declared for supported adapters; uniqueness/FK enforcement may be informational.
- **Data truth**: validated separately against an independent source and agreed business semantics.
- **Operational reliability**: monitored over time with alert/action ownership, not inferred from green CI.
- **Privacy assurance**: permissions, data minimization, code review and threat analysis, not a string pattern test.

## Checklist for a new project

Write a one-page decision record:
1. Model grain, consumer, authoritative source and top three credible costly failures.
2. Which native/community/custom tests are chosen, which are **not**, and their rationale.
3. Which negative mutation would break each chosen contract.
4. Freshness, volume, identity/NULL, late-arrival, history and reconciliation policies.
5. Adapter, dbt version, query-cost budget, failure-output sensitivity and escalation owner.
6. A review trigger (incident, new source, major version, cost increase, scope change).

## Applying this register

The most serious mistake would be turning a justified **defer** in this project into a universal **do not use**. Reassess against the next problem's data and operating constraints. Conversely, copying all macros because they are available is unnecessary complexity rather than risk-focused coverage. Keep version and compatibility claims grounded in current maintainers' documentation. Never claim a survey or example fixture proves a new warehouse is safe.

References: [dbt incremental models](https://docs.getdbt.com/docs/build/incremental-models), [dbt incremental strategies](https://docs.getdbt.com/docs/build/incremental-strategy?version=1.12), [dbt snapshots](https://docs.getdbt.com/docs/build/snapshots?version=1.12), [dbt-unit test overrides](https://docs.getdbt.com/reference/resource-properties/unit-test-overrides?version=1.12).

---

[← README](../README.md) · [Case study](when-clean-data-lies.md) · [All docs](README.md)
