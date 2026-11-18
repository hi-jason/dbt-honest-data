# Changelog

## 1.1.7 (unreleased)

- Group SQL `row_filter` predicates in `not_in_the_future` so an OR condition cannot bypass the future-date guard.
- Compare compatible SQL key types directly in `every_row_accounted_for` and `partitions_into`; cast identities to text only for human-readable diagnostics.
- Add INTEGER/DECIMAL equivalence, grouped-OR false-positive, and in-scope future-date regressions.
- Compare `known_cases` pins by their YAML type, so a pinned `15` matches a stored `15.00` and `true` matches a boolean; add typed regressions.
- Label rows with no identity correctly in `one_row_per_identity` when several of them group together.
- Parse `kill_switch_holds`'s switch with the shared `boolean_argument` helper.
- Raise the minimum dbt version to 1.10, which the `arguments:` test syntax needs.
- Examples: the advanced incremental model re-reads a lookback window and dedupes within a batch, so the replay now proves the upsert is idempotent; the starter's orphan-product policy and its `relationships` tests now agree (warn, not fail).
- Verify 38 clean and 44 deliberately failing core assertions; preserve source definition and fixture inventories.
- Inspect stored synthetic failure reasons and row counts for five high-risk regression cases; keep negative test results in disposable databases.
- Rewrite documentation for a technical audience.

## 1.1.6

- Strengthened metadata fail-closed behavior, exact fixture inventories, and source-definition review locks.
- Added regressions for missing tables, invalid values, and nullable identity controls.
- Core synthetic baseline: 33 clean PASS, 42 deliberately invalid FAIL, 22 Python checks.

## 1.1.5

- Normalized explicitly configured boolean values, including quoted "false", and rejected unknown tokens.

## 1.1.4

- Validated the core synthetic suite on PostgreSQL 16 in addition to DuckDB, including adapter-specific fixture corrections.

## 1.1.3

- Treated blank provenance labels as missing; rejected source-wide coverage claims with NULL scope.

## 1.1.2

- Hardened exact-identity and reference-case checks and invalid option handling.

## 1.1.1

- Closed source-NULL, source/partition duplicate, and unscoped-output blind spots. Added stricter result validation.

## 1.1.0 — 2026-11-10

- Added ten reusable checks for identity, partition, stage ordering, future dates, pinned cases, value tripwires, feature switches, segment rates, grading coverage, and duplicate identities.

## 1.0.0 — 2026-09-05

- Initial provenance, coverage, evidence, interval, column-name and population-rate contracts.
