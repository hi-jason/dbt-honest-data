# Reusable dbt test pattern catalog
## Choose a test before writing custom SQL

This catalog helps you match a **specific way data could be wrong** with a check that can catch it. It is a selection guide, not a list of installed packages or proof that any test works in your database. Start with built-in dbt tests. Then consider an optional package or a specialized check only when needed. For decisions and exclusions, see the [decision register](AE_EXCLUSIONS_AND_DECISIONS.md); for a step-by-step rollout, see the [playbook](AE_QUALITY_PLAYBOOK.md). Verify versions and database support before adopting a test.

| Failure hypothesis | First choice | Alternative / extension | Extra check often forgotten |
|---|---|---|---|
| Required ID null | native `not_null` | model contract where supported | Rows exist at all |
| Repeated natural key | native `unique` | `dbt_utils.unique_combination_of_columns` | Distinguish duplicate entity vs system version |
| Duplicate composite grain | `dbt_utils.unique_combination_of_columns` | local `group by ... having count(*)>1` | Required key component non-null |
| Invalid enumerated state | native `accepted_values` | `dbt_utils.not_accepted_values` | Explicit not-null for required state |
| Invalid numeric/date range | `dbt_utils.accepted_range` | `expression_is_true` | Null policy and time zone |
| Inconsistent arithmetic | `dbt_utils.expression_is_true` | business singular test | Null and floating tolerance, rounding |
| Missing FK parent | native `relationships` | `dbt_utils.relationships_where` for legitimate lag | Null foreign key policy; late arrival |
| Blank string stored as value | `dbt_utils.not_empty_string` | explicit trim test | Tabs, Unicode blanks, null |
| Non-null proportion falls | `dbt_utils.not_null_proportion` | `honest_data.declared_rate_band` | Group disparity and zero population |
| Unknown source freshness | `dbt source freshness` (dbt 1.x) | `dbt freshness` (dbt v2) | Current data may still be incomplete |
| Missing observed dates | `dbt_utils.sequential_values` for continuous series | expected calendar/period spine | Gaps tolerated by business schedule |
| Unnatural row-count change | `dbt_utils.equal_rowcount` or `fewer_rows_than` | baseline volume anomaly monitor | Two sides can agree while both wrong |
| No surviving records | `dbt_utils.at_least_one` / explicit nonempty test | `honest_data.still_grading` on filtered scope | Does the exact *expected* subset exist? |
| Constant/stuck source | `dbt_utils.not_constant` | anomaly/drift trend | Small population and known stable domain |
| Equal contents across two models | `dbt_utils.equality` | `dbt-audit-helper` for diagnostics | Comparable scope, identity and rounding |
| Data lost or invented in transform | `honest_data.every_row_accounted_for` | FK + source/target reconciliations | Duplicate keys and NULL source |
| Accepted/quarantined overlap/gap | `honest_data.partitions_into` | local exclusive/exhaustive test | Data routed into both partitions |
| Two system IDs for same entity | `honest_data.one_row_per_identity` | business de-duplication rules | Unknown identities treated separately |
| Nonmonotonic lifecycle | `honest_data.stages_are_monotonic` | expression check | Null stages, reversal, equal timestamps |
| Bad temporal uncertainty window | `honest_data.bounds_are_a_window` | local interval assertion | Avoid false exact timestamp |
| Source-wide claim now contradicted | `honest_data.coverage_claim_holds` | local scoped contradiction test | Null/blank source scope |
| Value missing its provenance label | `honest_data.provenance_is_paired` | local paired null test | Two-way polarity and blank label |
| Claim not backed by evidence | `honest_data.claim_requires_evidence` | `expression_is_true` | Evidence-only records missing claims |
| Known pinned case drifts or vanishes | `honest_data.known_cases` | native unit tests for transform logic | Missing anchor must fail |
| Switch OFF yet rows exist | `honest_data.kill_switch_holds` | local conditional absence check | Quoted string boolean handling |
| One segment misbehaves inside average | `honest_data.grouped_share_in_band` | grouped expectations | Small/omitted groups |
| Sensitive schema field appears | Explicit **projection allowlist** + `no_column_names_matching` | model contract; `no_column_names_matching` | Missing model/schema and renamed columns |
| Sensitive marker inside text | `honest_data.no_values_matching` for synthetic canary | approved value scanner | Never print matched real secrets |
| Migrating schema/data | `dbt-audit-helper` comparisons | `dbt_utils.equality` | Identify material changes; safe logs |
| Data quality drift | Scheduled historical monitoring | Optional observability provider | Human owner, false alerts, noise |
| Incremental replay divergence | Native dbt SQL unit tests + replay integration | local stateful test | Materialization outcome, late arrival |
| Snapshot history overlap | Interval/non-overlap custom assertion or `dbt_utils.mutually_exclusive_ranges` where applicable | one-current-version and composite grain | Handle open-ended NULL valid_to explicitly; hard deletes, backfills, timezones |

## Suggested minimal starting set

- **Native four** on the selected critical keys/states: `unique`, `not_null`, `relationships`, `accepted_values`.
- **One purpose-built high-risk check** on each critical model: select from `dbt-utils` or `honest-data` based on specific expected failure.
- **A non-vacuity check** when an empty/missing population would defeat the assertion.
- **A seeded valid/corrupted pair**, with explicit acceptance of only PASS for valid and FAIL for corrupt; an ERROR is not evidence the contract caught the defect.
- **A freshness/monitoring owner** for pipelines serving humans and downstream automation.
- **A privacy decision** for failure rows, compiled SQL, secrets in logs and restricted model metadata.

## Checks that look similar but answer different questions

- **`unique` vs `one_row_per_identity`:** storage key uniqueness does not catch two different keys referring to one real-world entity.
- **`equal_rowcount` vs `every_row_accounted_for`:** equal counts do not establish matching identities.
- **`not_null_proportion` vs `declared_rate_band`:** both measure how often values are present. The latter compares that rate with a stated band; neither verifies that a value marked "measured" was actually observed.
- **`relationships` vs `partitions_into`:** finding a related record does not prove each input record went to exactly one output group, with none lost or added.
- **`accepted_values` vs domain truth:** allowed categories can be perfectly valid while classifications are systematically wrong.
- **Source freshness vs event freshness:** recent ingestion metadata does not prove events are recent or that all expected observations arrived.
- **Contracts vs unique tests:** adapter constraint enforcement varies. A declared PK/unique constraint may be metadata only; keep data assertions on critical grain. See [dbt model contracts and constraint support](https://docs.getdbt.com/docs/mesh/govern/model-contracts?version=1.12).
- **Metamorphic correctness vs exact oracle:** invariance after reordering input or re-running a deterministic transform is helpful but cannot prove agreement with reality.

## References to verify before reuse

- [dbt native tests](https://docs.getdbt.com/docs/build/data-tests)
- [dbt utils reusable generic tests](https://github.com/dbt-labs/dbt-utils)
- [dbt audit helper](https://github.com/dbt-labs/dbt-audit-helper)
- [dbt unit tests](https://docs.getdbt.com/docs/build/unit-tests)
- [dbt source freshness](https://docs.getdbt.com/docs/deploy/source-freshness)
- [dbt incremental/snapshot guidance](https://docs.getdbt.com/best-practices/how-we-handle-cdc/2-choosing-incremental-or-snapshots)

**Version caveat:** the v1.1.7 synthetic suite uses dbt-core 1.12.6 with DuckDB and PostgreSQL. This catalog does not install optional packages or run its examples. A new database adapter needs its own validation.

---

[← README](../README.md) · [Case study](when-clean-data-lies.md) · [All docs](README.md)
