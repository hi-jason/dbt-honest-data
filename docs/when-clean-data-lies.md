# When clean data lies: what 83,965 job-listing snapshots taught me

*By [Jason Yi](https://github.com/hi-jason) · Code written with AI coding assistance; the audit, design decisions and lessons are mine.*

*About 8 minutes · [← Back to the README](../README.md)*

I audited **83,965 snapshots from five public job-listing feeds**. The most important errors were not crashes or empty columns: **18,536 estimated posting dates looked exact**, **41.8% of records were treated as open without confirmation**, and a change filter **hid a real 17% pay increase**.

The data was often present and correctly typed. What was wrong was the *meaning* readers would take from it.

This case study covers what a ten-day audit found, the engineering decisions it led to, and the dbt checks I extracted into [`dbt-honest-data`](../README.md).

## The investigation

Five public listing feeds supplied records with different fields, different definitions, and no single authoritative schema. The pipeline collected append-only snapshots and used dbt transformations to produce a more usable view. A ten-day audit covered:

| Audited population | Observed |
| --- | ---: |
| Snapshots collected | **83,965** |
| Distinct listings represented | **50,348** |
| Listings with more than one version | **17,100** |
| Feeds | **5** |

The high-level lesson was unsettling: **a value can be present, correctly typed, and internally consistent while its interpretation is wrong**.

The investigation involved source interpretation, modeling, and detection logic. Not every finding can be fixed with a generic dbt test; the distinction matters.

## 1. A complete date column that made estimates look exact

**Observed defect.** One feed returned relative text such as `Posted 3 Days Ago` rather than an absolute timestamp. The pipeline subtracted three days from the fetch time and placed the result in a date column. For `Posted 30+ Days Ago`, it treated a lower bound as a precise 30-day value.

The column looked healthy: **18,536 rows** had an inferred value, and none were missing. Conventional non-null checks had little reason to complain.

**Design decision.** A parsed timestamp needed an accompanying *precision contract*: `exact`, `day_approximated`, or `censored_floor`. The value and the label travel together. A later source investigation located an exact date field and moved **19,031 records** to an `exact` classification in a subsequent analysis. Those historical counts are not a before/after conversion rate: the populations and audit points differ.

**Reusable check.** [`provenance_is_paired`](../macros/provenance_is_paired.sql) catches values without their required precision labels and labels without values, according to configuration. Add dbt `accepted_values` to constrain the vocabulary. Neither test can prove an `exact` label was assigned honestly; that requires source-level evidence.

**Why it matters.** An inaccurate publication date affects freshness ranking, age analyses, and decisions about whether a listing is worth investigating. A populated date column is not the same as a measured date column.

## 2. “Not closed” was quietly converted into “open”

**Observed defect.** The modeled status treated `is_closed = false` as “open” for **41.8% of the corpus**. The problem was logical: the absence of confirmed closure does not establish current availability.

**Design decision.** Availability should represent what the source actually tells us—for example, `confirmed_open`, `confirmed_closed`, and `unknown`—along with an observation time and source evidence when available. A listing with no reliable status stays `unknown`, even when a dashboard would prefer a yes/no answer.

**Reusable check.** [`known_cases`](../macros/known_cases.sql) can pin representative source-to-status mappings; [`claim_requires_evidence`](../macros/claim_requires_evidence.sql) can check that any `confirmed_open` claim has an appropriate source-status predicate. **There is no single generic macro that independently proves a listing remains open.** This defect requires the upstream status semantics to be corrected first.

**Why it matters.** A perfectly valid Boolean can create a false sense of certainty. The correct response is sometimes to preserve a third state rather than force a binary field.

## 3. A NULL salary field with two incompatible explanations

**Observed defect.** `pay_min IS NULL` could mean “the publisher disclosed no pay” **or** “the ingestion code doesn't support pay for this feed.” One source showed **0.0% parsed-pay coverage across 18,536 rows**. The identical NULL values hid those very different causes.

**Design decision.** Track a reason such as `not_disclosed`, `no_parser_for_source`, or `parse_failed`. Just as important, define *scope*: `not_disclosed` applies to an individual record, while `no_parser_for_source` is a statement about the integration for that feed. If even one row from the claimed source has a valid parsed amount, the categorical source-wide claim is contradicted.

**Reusable checks.** [`provenance_is_paired`](../macros/provenance_is_paired.sql) verifies value/absence-reason consistency; [`coverage_claim_holds`](../macros/coverage_claim_holds.sql) checks whether source-scoped claims are contradicted by observed data.

**Why it matters.** A report about pay disclosure cannot distinguish market behavior from a parser gap unless the data model makes that difference explicit.

## 4. Polling told us *when we noticed*, not when the event occurred

**Observed defect.** Comparing snapshots establishes that a field changed *between two observations*. In one case the change was bounded by **five days**, yet a transformation assigned a single `changed_at` timestamp. An analysis of the “time publishers edit listings” could therefore reflect the polling schedule rather than publisher behavior.

**Design decision.** Store `changed_after` and `changed_before`. Expose the range honestly—“changed between the 12th and the 17th”—rather than promote an observation timestamp to an event timestamp.

**Reusable check.** [`bounds_are_a_window`](../macros/bounds_are_a_window.sql) rejects missing, inverted, or otherwise invalid bounds under its configured policy. It does not identify the event's exact time inside the interval.

## 5. Fixing noisy change alerts accidentally hid a meaningful pay rise

A change detector initially produced false signals:

| Audit observation | Underlying issue |
| --- | --- |
| **66 transitions** with large raw-text changes but identical visible text | The detector treated formatting/serialization changes as content edits |
| **65 of 401** apparent compensation changes | One feed reordered elements in a compensation array |
| **856 listings** with inflated edit counts | A countdown such as “10 days left to apply” changed on each collection |

Filtering the noise seemed obvious. But that created a second problem: **a legitimate salary-basis change was thrown away**.

A displayed figure moved from **$140,000** to **$75**. As raw numbers, that looked like bad parsing. In context, the position had shifted from **annual to hourly pay**, a meaningful exempt/non-exempt reclassification. The annualized upper bound changed from **$160,000 to $187,200**, a **17% increase**. The noise filter suppressed the change rather than reporting the basis switch and higher upper bound.

**Design decisions:**

1. Normalize and compare amounts **with their pay basis**, rather than judging a change solely by its raw numeric magnitude.
2. Define which fields can support a material edit—such as compensation, location, title, and description—rather than attempting to blacklist every source of noise.
3. **Label suppressed events instead of deleting them.** Keep a reviewable record of what was ignored and why.
4. Review anomalous but legitimate changes, rather than treating unfamiliar values as errors by default.

**Reusable check.** [`claim_requires_evidence`](../macros/claim_requires_evidence.sql) checks that a `material` change classification agrees with configured evidence, potentially in both directions. That helps guard the resulting change-data contract. **It does not, by itself, discover a salary-basis change or undo an upstream filter that already deleted the record.** Preserving suppressed rows is a separate architectural decision.

**Why it matters.** Noise reduction creates its own blind spot. A monitoring system that looks clean because it deleted inconvenient events may be less reliable than one that preserves uncertainty and review trails.

## 6. Field presence and field volatility are not the same as usefulness

A source/field volatility monitor exposed differences in how often fields changed across consecutive versions. The figures below are **historical observed transition rates**; feed identities are anonymized:

```text
99.6%  postedOn          feed A
96.2%  updated_at        feed B
77.0%  timeLeftToApply   feed A
54.1%  descriptionHtml   feed C
```

The first three deserve scrutiny as timestamps or countdown mechanics. The last is different: descriptions can change often *and* contain material information. A high change rate is a diagnostic signal, not grounds for automatic deletion.

**Design decision.** Declare whether a value is `measured`, `derived`, `approximated`, `defaulted_when_unknown`, or `absent_by_design`. Independently track whether its observed population rate remains within a defensible range.

**Reusable check.** [`declared_rate_band`](../macros/declared_rate_band.sql) checks the observed share against a declared band. Field-volatility analysis and materiality judgments remain separate upstream processes.

## From investigation to reusable tests

The original six contracts were motivated by these failures: `provenance_is_paired`, `coverage_claim_holds`, `claim_requires_evidence`, `bounds_are_a_window`, `no_column_names_matching`, and `declared_rate_band`. Later work added distinct-key conservation, exact partitioning, pinned reference cases, grading coverage, and other safeguards.

An additional insight emerged while testing the tests: *checking that a deliberately broken dataset returned FAIL isn't sufficient if it failed for the wrong reason*. The current synthetic suite therefore verifies all selected test identities and their status; for **five high-risk negative fixtures** it also checks the actual failure labels and row counts. Those cases run on DuckDB and PostgreSQL, using invented fixtures rather than reproductions of the audit data.

## What changed in how I approached data quality

Before this audit, a straightforward checklist—non-null, unique, accepted values, valid joins—could make an output appear adequately tested. It wasn't enough for a system expected to explain *when a posting appeared, whether it was active, what compensation was disclosed, and what changed*.

I came away with three practical rules:

- **Model uncertainty instead of disguising it.** “Unknown” and “approximately” are useful data states.
- **Test the relationship between a claim and its evidence.** A green dashboard should not be able to make an unsupported claim silently.
- **Don't throw away exceptions just to reduce noise.** Preserve enough context for someone to audit the suppression decision.

These checks make certain mistakes more visible, but they cannot establish that the source is correct, that a suppressed record is meaningful, or that the same SQL performs well in every warehouse. Those are separate verification problems—and identifying the boundary is part of good data engineering.

## Where to go next

- **See the checks on a model:** the README's [examples](../README.md#how-the-checks-attach-to-a-model) attach them to a listings model and a staging model.
- **Read one check's code:** start with [`provenance_is_paired`](../macros/provenance_is_paired.sql), finding 1's check. Its comment block explains the defect, both directions it tests, and its arguments.
- **See it fail on purpose:** [how the tests are tested](../integration_tests/README.md) walks through the harness and links every check's passing and planted-error fixtures.
- **When not to use these:** the [testing playbook](AE_QUALITY_PLAYBOOK.md) and the [decision register](AE_EXCLUSIONS_AND_DECISIONS.md).

*The audit figures are historical measurements from public listing feeds, not benchmarks or counts of problems the package fixed automatically. The underlying records are not in this repository; the tests in CI use separately built synthetic data.*
