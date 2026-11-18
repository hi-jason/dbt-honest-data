# How the tests are tested

*Part of [dbt-honest-data](../README.md) · [Case study](../docs/when-clean-data-lies.md) · [All docs](../docs/README.md)*

A data test that never fails proves nothing. This folder holds small, invented tables built to **pass** every check and others built to **break** one on purpose, plus the scripts that confirm each check behaves as intended on both. CI runs it all on DuckDB and PostgreSQL.

## What `run.sh` does, in order

[`run.sh`](run.sh) stops at the first step that goes wrong.

1. **Self-tests and the source lock.** It unit-tests the Python validators, then [`verify_contract_sources.py`](verify_contract_sources.py) compares the test definitions with fingerprints in [`expected_contract_sources.json`](expected_contract_sources.json). A test definition can't change without the lock being updated deliberately.
2. **Builds every fixture table** with `dbt run`.
3. **Passing phase.** It runs the checks on the clean tables ([`models/honest/`](models/honest/)). [`validate_results.py`](validate_results.py) requires every one to PASS, and requires the exact list of 38 tests in [`expected_case_catalog.json`](expected_case_catalog.json): a skipped or missing test fails the run.
4. **Planted-error phase.** It runs the checks on the broken tables ([`models/dishonest/`](models/dishonest/)) and saves the failing rows. Each of the 44 tests must **FAIL**. An SQL error, a skip, or an unexpected pass all count as the check not working.
5. **Reason check.** [`verify_failure_reasons.py`](verify_failure_reasons.py) reads the saved failing rows for five high-risk cases and confirms each failed *for the right reason*, with the expected failure label and row count.
6. **Bad configuration.** [`test_invalid_config.py`](test_invalid_config.py) confirms an invalid switch value is rejected with the intended message.

## Worked example: `provenance_is_paired`

- **The check:** [`macros/provenance_is_paired.sql`](../macros/provenance_is_paired.sql). A value and its label (an estimated date and its precision, or a missing salary and its reason) must appear together.
- **Must pass:** [`jobs_labelled`](models/honest/jobs_labelled.sql). Every inferred date has its label, and every missing salary has its reason.
- **Must fail:** [`jobs_unlabelled_dates`](models/dishonest/jobs_unlabelled_dates.sql) reproduces the original defect, a derived date with no label. Its siblings cover a blank label, a blank reason, and a missing salary with no reason.
- **How they're wired:** each test is attached to its table in [`models/honest/schema.yml`](models/honest/schema.yml) and [`models/dishonest/schema.yml`](models/dishonest/schema.yml).

## Every check and its fixtures

| Check | Must pass | Must fail |
| --- | --- | --- |
| [`provenance_is_paired`](../macros/provenance_is_paired.sql) | [`jobs_labelled`](models/honest/jobs_labelled.sql) | [`absence_blank_reason`](models/dishonest/absence_blank_reason.sql), [`jobs_unattributed_absence`](models/dishonest/jobs_unattributed_absence.sql), [`jobs_unlabelled_dates`](models/dishonest/jobs_unlabelled_dates.sql), [`precision_blank_label`](models/dishonest/precision_blank_label.sql) |
| [`coverage_claim_holds`](../macros/coverage_claim_holds.sql) | [`coverage_nonclaim_null_scope`](models/honest/coverage_nonclaim_null_scope.sql), [`jobs_labelled`](models/honest/jobs_labelled.sql) | [`coverage_claim_null_scope`](models/dishonest/coverage_claim_null_scope.sql), [`jobs_false_coverage_claim`](models/dishonest/jobs_false_coverage_claim.sql) |
| [`claim_requires_evidence`](../macros/claim_requires_evidence.sql) | [`changes_coherent`](models/honest/changes_coherent.sql) | [`changes_claim_without_evidence`](models/dishonest/changes_claim_without_evidence.sql) |
| [`bounds_are_a_window`](../macros/bounds_are_a_window.sql) | [`changes_coherent`](models/honest/changes_coherent.sql) | [`changes_point_in_time`](models/dishonest/changes_point_in_time.sql), [`equal_window_quoted_false`](models/dishonest/equal_window_quoted_false.sql) |
| [`every_row_accounted_for`](../macros/every_row_accounted_for.sql) | [`listings_latest`](models/honest/listings_latest.sql), [`numeric_keys_derived`](models/honest/numeric_keys_derived.sql) | [`derived_missing_null`](models/dishonest/derived_missing_null.sql), [`duplicates_disabled_quoted_false`](models/dishonest/duplicates_disabled_quoted_false.sql), [`extras_disabled_quoted_false`](models/dishonest/extras_disabled_quoted_false.sql), [`latest_drops_and_invents`](models/dishonest/latest_drops_and_invents.sql) |
| [`partitions_into`](../macros/partitions_into.sql) | [`listings_source`](models/honest/listings_source.sql), [`numeric_keys_derived`](models/honest/numeric_keys_derived.sql), [`scoped_source_clean`](models/honest/scoped_source_clean.sql) | [`input_duplicate_keys`](models/dishonest/input_duplicate_keys.sql), [`part_duplicate_source`](models/dishonest/part_duplicate_source.sql), [`part_null_source`](models/dishonest/part_null_source.sql), [`scoped_source_bad`](models/dishonest/scoped_source_bad.sql), [`source_badly_split`](models/dishonest/source_badly_split.sql) |
| [`known_cases`](../macros/known_cases.sql) | [`cases_typed_values`](models/honest/cases_typed_values.sql), [`missing_case_quoted_false_ok`](models/honest/missing_case_quoted_false_ok.sql), [`titles_classified`](models/honest/titles_classified.sql) | [`cases_duplicate_actual`](models/dishonest/cases_duplicate_actual.sql), [`cases_duplicate_pin`](models/dishonest/cases_duplicate_pin.sql), [`cases_wrong_number`](models/dishonest/cases_wrong_number.sql), [`titles_misclassified`](models/dishonest/titles_misclassified.sql) |
| [`grouped_share_in_band`](../macros/grouped_share_in_band.sql) | [`holds_by_source`](models/honest/holds_by_source.sql), [`ungraded_band_quoted_false_ok`](models/honest/ungraded_band_quoted_false_ok.sql) | [`groups_all_too_small`](models/dishonest/groups_all_too_small.sql), [`holds_out_of_band`](models/dishonest/holds_out_of_band.sql) |
| [`not_in_the_future`](../macros/not_in_the_future.sql) | [`filter_or_precedence_ok`](models/honest/filter_or_precedence_ok.sql), [`lifecycle_in_order`](models/honest/lifecycle_in_order.sql) | [`export_from_the_future`](models/dishonest/export_from_the_future.sql), [`filter_or_future_in_scope`](models/dishonest/filter_or_future_in_scope.sql) |
| [`stages_are_monotonic`](../macros/stages_are_monotonic.sql) | [`equal_stage_quoted_false_ok`](models/honest/equal_stage_quoted_false_ok.sql), [`lifecycle_in_order`](models/honest/lifecycle_in_order.sql) | [`lifecycle_out_of_order`](models/dishonest/lifecycle_out_of_order.sql) |
| [`still_grading`](../macros/still_grading.sql) | [`dates_gradable`](models/honest/dates_gradable.sql) | [`dates_none_gradable`](models/dishonest/dates_none_gradable.sql), [`empty_grading_quoted_false`](models/dishonest/empty_grading_quoted_false.sql), [`graded_population_empty`](models/dishonest/graded_population_empty.sql) |
| [`no_column_names_matching`](../macros/column_name_denylist.sql) | [`public_safe`](models/honest/public_safe.sql) | [`public_leaky`](models/dishonest/public_leaky.sql) |
| [`schema_name_denylist`](../macros/column_name_denylist.sql) | [`schema_name_denylist_existing_schema`](tests/honest/schema_name_denylist_existing_schema.sql), [`schema_name_denylist_two_existing`](tests/honest/schema_name_denylist_two_existing.sql) | [`schema_name_denylist_absent_schema`](tests/dishonest/schema_name_denylist_absent_schema.sql), [`schema_name_denylist_absent_table`](tests/dishonest/schema_name_denylist_absent_table.sql), [`schema_name_denylist_forbidden_column`](tests/dishonest/schema_name_denylist_forbidden_column.sql), [`schema_name_denylist_partial_missing`](tests/dishonest/schema_name_denylist_partial_missing.sql), [`schema_name_denylist_required_missing`](tests/dishonest/schema_name_denylist_required_missing.sql) |
| [`no_values_matching`](../macros/no_values_matching.sql) | [`public_values_clean`](models/honest/public_values_clean.sql), [`public_values_structured_clean`](models/honest/public_values_structured_clean.sql) | [`public_values_leaky`](models/dishonest/public_values_leaky.sql), [`public_values_structured_leaky`](models/dishonest/public_values_structured_leaky.sql) |
| [`one_row_per_identity`](../macros/one_row_per_identity.sql) | [`identity_multiple_unidentified_allowed`](models/honest/identity_multiple_unidentified_allowed.sql), [`identity_optional_null_ok`](models/honest/identity_optional_null_ok.sql), [`listings_latest`](models/honest/listings_latest.sql), [`nullable_identity_quoted_false_ok`](models/honest/nullable_identity_quoted_false_ok.sql) | [`identity_blank`](models/dishonest/identity_blank.sql), [`identity_null`](models/dishonest/identity_null.sql), [`listings_shadowed`](models/dishonest/listings_shadowed.sql) |
| [`declared_rate_band`](../macros/declared_rate_band.sql) | [`empty_rate_quoted_false_ok`](models/honest/empty_rate_quoted_false_ok.sql), [`jobs_labelled`](models/honest/jobs_labelled.sql) | [`jobs_rate_below_band`](models/dishonest/jobs_rate_below_band.sql) |
| [`kill_switch_holds`](../macros/kill_switch_holds.sql) | [`partner_off_string_ok`](models/honest/partner_off_string_ok.sql), [`partner_on_string_ok`](models/honest/partner_on_string_ok.sql), [`partner_rows_switch_off`](models/honest/partner_rows_switch_off.sql), [`partner_rows_switch_on`](models/honest/partner_rows_switch_on.sql) | [`partner_rows_despite_switch_off`](models/dishonest/partner_rows_despite_switch_off.sql) |

`no_column_names_matching` and `schema_name_denylist` are two forms of one check, a table-level test and a schema-wide singular test, both in `column_name_denylist.sql`.

## Run it

```bash
bash integration_tests/run.sh
```

Use a disposable environment with dbt Core 1.10+ and the DuckDB adapter, or set `HONEST_DATA_TARGET=postgres` for a disposable local PostgreSQL. [`profiles.yml`](profiles.yml) holds the synthetic-only connection settings.
