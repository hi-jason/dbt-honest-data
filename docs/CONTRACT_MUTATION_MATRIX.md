# Mutation matrix

The core suite verifies **38 passing assertions** and **44 deliberately failing assertions**. The runner also checks selected node identities and a reviewed source manifest. For five targeted cases—two future-date failures, key conservation, partition coverage, and rows with no identity—it queries stored synthetic failure rows and verifies the exact failure reason labels and counts. The remaining negative fixtures are still validated by status and inventory, not by a golden reason multiset.

| Failure class | Example mutation | Intended contract |
| --- | --- | --- |
| Missing precision label | Value present, label blank | [`provenance_is_paired`](../macros/provenance_is_paired.sql) |
| Source-wide absence contradiction | Coverage claim with a populated value | [`coverage_claim_holds`](../macros/coverage_claim_holds.sql) |
| Unsupported material change | Claim has no evidence | [`claim_requires_evidence`](../macros/claim_requires_evidence.sql) |
| Invalid interval | End precedes start | [`bounds_are_a_window`](../macros/bounds_are_a_window.sql) |
| Lost/invented key | Source and derived identities diverge | [`every_row_accounted_for`](../macros/every_row_accounted_for.sql) |
| Incomplete/overlapping split | Record absent from all parts or duplicated across parts | [`partitions_into`](../macros/partitions_into.sql) |
| Incorrect reference record | Reviewed case differs from expected value | [`known_cases`](../macros/known_cases.sql) |
| Hidden segment failure | One segment violates a share band | [`grouped_share_in_band`](../macros/grouped_share_in_band.sql) |
| SQL filter precedence | An OR branch bypasses the date condition | [`not_in_the_future`](../macros/not_in_the_future.sql) |
| Numeric type equivalence | Integer 1 compared with decimal 1.0 | [`every_row_accounted_for`](../macros/every_row_accounted_for.sql), [`partitions_into`](../macros/partitions_into.sql) |
| Typed reference values | A pinned 15 against a stored 15.00, or `true` against a boolean | [`known_cases`](../macros/known_cases.sql) |
| Mislabelled missing identity | Two rows with no identity reported as one shared identity | [`one_row_per_identity`](../macros/one_row_per_identity.sql) |
| Missing inspected population | Filter selects zero records | [`still_grading`](../macros/still_grading.sql) |
| Schema metadata disappears | Name guard sees no tables/columns | [`no_column_names_matching`](../macros/column_name_denylist.sql) |

## Tests that matter during review

Positive controls for filter grouping, numeric key types, and typed reference values are especially important because they catch **false positives**, not just undetected bad records. Negative controls must also be narrowly scoped so a test cannot pass by failing for an unrelated reason.

The harness rejects an empty selection, missing or duplicate node IDs, unexpected model/macro inventory, SQL execution ERROR instead of assertion FAIL, or changes to reviewed schema/test definitions without a source-manifest update. The source hash is a change-review tripwire, not a cryptographic attestation.

Every check's runnable fixtures are listed in [how the tests are tested](../integration_tests/README.md#every-check-and-its-fixtures); the exact expected test list is [`expected_case_catalog.json`](../integration_tests/expected_case_catalog.json).

---

[← README](../README.md) · [Case study](when-clean-data-lies.md) · [All docs](README.md)
