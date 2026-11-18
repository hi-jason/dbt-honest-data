# Testing playbook
## Reusable dbt-first testing guide · November 2026

**Use this guide when:** starting an analytics project, moving data models, fixing a dashboard error, or changing dbt code. It is a practical guide, not an industry standard. Examples use made-up data and do not install dependencies or change production settings.

## 1. Initial assessment

1. **Describe the table and what must be true.** Who uses it, and to make which decision? What does one row represent (often called its *grain*)? Which source is trusted, what may be estimated, and what information is private?
2. **Classify failure risks** by dimension: validity, completeness, uniqueness, consistency, freshness, accuracy, interpretability/provenance, historical correctness, confidentiality, cost.
3. **Pick highest consequence failures first.** Breakage that can mislead an executive, finance report, published model or automated action needs an explicit *owner*, not simply a warning.
4. **Choose the simplest effective check.** First make the model's design clear. Try a built-in dbt test, then a compatible community test, then a specialized or business-specific test. Add monitoring only if someone will use it. If an empty table or empty filtered group would hide a defect, check that it contains records.
5. **Show that the check catches the mistake.** Run it on a small made-up example that should pass and another with the targeted mistake. The broken case must fail **because the test found bad data**, not because SQL errored, the test was skipped, or no data was inspected.
6. **Stage and operate**: unit tests in dev/CI, source freshness on a separate schedule, targeted data tests after build, heavier reconciliation on promotion or schedule.
7. **Document** the allowed exception, expected alert path, privacy of failure artifacts, query cost, runtime, and which parts still are not covered.

**Default approach to package selection:** Start with native dbt. Add *dbt-utils* when one of its specific macros avoids custom SQL. Import *honest-data* only for a concrete epistemic/coverage/reconciliation hazard. Add audit-helper for migrations, not for ordinary daily checks. Make expectations/observability optional with a cost and operations justification.

## 2. Suggested testing tiers

| Tier | When | Minimum assertions | Required evidence |
|---|---|---|---|
| T0 — Every consumer-facing model | Every project | declared grain, key not_null/unique, important accepted_values, necessary FKs, contract where supported, owner, basic freshness/population where relevant | YAML + docs + risk note |
| T1 — Important transforms | Joins, windows, case logic, incrementals | T0 + synthetic SQL unit cases and a deliberately failing synthetic case for highest-risk logic; row conservation where expected | CI outcome + mutation outcome |
| T2 — Critical decision/export | Finance/leadership/security or trusted downstream contract | T1 + reconciliation to authoritative source, segment checks, provenance, fresh evidence, privacy projection review, alert runbook | independent comparison and human sign-off |
| T3 — High-scale/long-lived | Multiple teams, many sources, daily SLAs | T2 + drift/volume/latency monitoring, scheduled partition tests, change budget and ownership | trend dashboard, review cadence, incident log |

The tier is based on **consequence of failure**, not model size or number of rows. Not every T2 contract needs every honest-data macro.

## 3. Reusable test recipes

### Recipe 1 — A dimension key is unique and nonempty

```yaml
version: 2
models:
  - name: dim_products
    description: "Synthetic: one row per product_id."
    config:
      contract:
        enforced: true # verify adapter and materialization support
    columns:
      - name: product_id
        data_type: varchar
        data_tests:
          - not_null
          - unique
      - name: status
        data_type: varchar
        data_tests:
          - not_null
          - accepted_values:
              arguments:
                values: ['active', 'retired', 'planned']
```

**Non-vacuity:** `unique` and `not_null` PASS on an empty model. If an empty dimension would be wrong, pair with a separate nonempty/population expectation. **Model contracts do not establish business correctness.** Adapter enforcement of unique/PK/FK constraints varies, and an adapter can record such constraints without enforcing them. Preserve data tests on critical grain. [dbt constraint support](https://docs.getdbt.com/docs/mesh/govern/model-contracts?version=1.12).

### Recipe 2 — Composite grain and valid arithmetic

```yaml
version: 2
models:
  - name: fct_monthly_revenue
    description: "Synthetic: one row per (month_start, product_id)."
    data_tests:
      - dbt_utils.unique_combination_of_columns:
          arguments:
            combination_of_columns: [month_start, product_id]
      - dbt_utils.expression_is_true:
          arguments:
            expression: "gross_amount - discount_amount = net_amount"
    columns:
      - name: month_start
        data_tests: [not_null]
      - name: product_id
        data_tests:
          - not_null
          - relationships:
              arguments:
                to: ref('dim_products')
                field: product_id
```

**Caveats:** Null arithmetic can yield UNKNOWN rather than FALSE in SQL. Set explicit nullable-field policy before treating an expression as comprehensive. Numeric equality should use currency precision/rounding rules, not arbitrary floating-point exactness.

### Recipe 3 — A few records must not represent an entire business process

- Sources: run freshness checks separately from `dbt build`. On this repo's 1.12 stack, use `dbt source freshness`. In dbt v2, the preferred command is `dbt freshness` and can also cover model freshness. Confirm the active version.
- Source is fresh but missing 99% of keys? Add an expected volume/partition or comparison test.
- Filter selects no rows? Add `honest_data.still_grading` or a nonempty explicit assertion, with explicit exception only when empty is valid.
- Column claims to be measured but 30% is defaulted? Consider `honest_data.declared_rate_band` or `dbt_utils.not_null_proportion` depending on the actual semantic claim.

### Recipe 4 — Every source key was accounted for

- If a transform should conserve identity, `honest_data.every_row_accounted_for(against=..., key=...)` checks missing, extra, duplicated keys.
- If a quarantine split must be exclusive and exhaustive, `honest_data.partitions_into(parts=..., key=...)` is a focused test.
- If migration compares old and new results, first validate comparable keys and data scope; use audit-helper for classified differences, not merely row count.
- Check null keys, duplicate keys, one side empty, extra keys, and partial filters explicitly.

### Recipe 5 — True as-of and history

- For SCD/snapshot tables: verify there is at most one current version per business key, unique key + effective_from, non-overlapping ranges, valid interval bounds.
- Native `unique` on (business key, version start) alone cannot prevent overlapping history.
- Check late-arriving records, backdated corrections, hard deletes, timezone/daylight boundaries, and replay/idempotence with synthetic examples.
- Prefer a snapshot when historical versions are needed; incremental tables alone can overwrite the history being requested.

### Recipe 6 — Avoid false precision and unsupported privacy assurances

- Derived approximate timestamps: keep an explicit provenance/precision label and verify it with `honest_data.provenance_is_paired`.
- Claims that demand evidence: `honest_data.claim_requires_evidence`.
- Public/export model: explicitly project allowed columns; use `no_column_names_matching` as a **secondary** tripwire and optional `no_values_matching` for safe canary tokens.
- Pattern-based checks do not certify privacy and may expose matched text in stored failure rows. Restrict who can see artifacts and diagnostics.

### Recipe 7 — Testing transformation logic, not just output shape

Native dbt SQL unit tests are suited to parsing, conditional branches, joins, date arithmetic, windows, and known regression cases. Test with small, clear synthetic inputs and expected outputs. For incrementals, test both fresh and incremental branches, and separately test database merge behavior; unit tests do not prove that materialization updates the final relation correctly.

Representative fixture categories:
- NULL, empty string, whitespace, zero, negative and unknown enum.
- Duplicated input rows, duplicate business IDs under distinct system keys.
- Cross joins or many-to-many joins that silently multiply facts.
- Missing relation on one side; stale/fresh mixed sources.
- Exact boundary on a range or timestamp; DST/offset; out-of-order events.
- Replacement of a measured value by inferred/sentinel fallback.
- One source or one segment entirely absent while aggregate remains plausible.


### Recipe 8 — Metamorphic tests when the exact answer is difficult

Use only when the transformation has a defensible invariant. Metamorphic testing is background theory, **not** a certification of these particular analytics checks.

- **Permutation invariance:** Reorder synthetic source rows without changing their content. A deterministic aggregation should return the same keyed results. This is not valid when order is semantically meaningful.
- **Split/recombine:** Partition a disjoint set of source keys, run the transform on both parts and combine results. This should agree with the transform on the whole **only when** cross-part joins, global ranks, and window effects do not change semantics.
- **Idempotence/replay:** Run an incremental load twice with identical input and clock assumptions. A true upsert should not invent extra records. Test materialization state, not just the compiled SELECT.
- **Conservation:** Add a synthetic source row known to pass a one-to-one mapping; the output key set should gain exactly that row. This property does **not** hold for non-additive metrics, deduplication, or global scores.

Each metamorphic check needs a stated assumption, a transformation of inputs, an expected relation between outputs, and a case where the relation would deliberately fail. Do not assert generic properties blindly across arbitrary SQL.

## 4. Quality contract template

```text
MODEL NAME:
BUSINESS PURPOSE / CONSUMERS:
OWNER / ESCALATION:
GRAIN ("one row per ..."):
AUTHORITATIVE INPUTS:
IDENTITY POLICY (NULL, duplicates, retries):
EXPECTED POPULATION / EMPTY MEANING:
SOURCE LATENCY / FRESHNESS SLA:
ACCEPTED STATES / BOUNDS:
RECONCILIATION OR NUMERIC INVARIANTS:
HISTORICAL AND LATE-ARRIVAL POLICY:
APPROXIMATIONS / SOURCE OF TRUTH / PROVENANCE:
PII / EXPORT ALLOWLIST / FAILURE-LOG EXPOSURE:
TEST SEVERITY + MUTATION EXAMPLE:
WHEN RUN + COST CEILING:
KNOWN BLIND SPOTS:
APPROVAL / REVIEW DATE:
```

If this information is not known, do not invent a threshold or mark the data "certified". Record the gap explicitly, find an owner, and start with tests whose meaning is incontrovertible.

## 5. CI and operating checks

| Stage | Check | Stop condition |
|---|---|---|
| Pull request | Parse/compile, model contract/static checks where available, native unit tests, focused synthetic data tests | ERROR, unexpected PASS of mutation, changed unsanctioned contract args |
| Pre-merge staging | Build impacted DAG in isolated schema, check grain/FKs, selected reconciliation | Any high-consequence integrity failure |
| Promotion | New versus old output diff on same population/key; source freshness where applicable | Unexplained material differences or unsafe sensitive columns |
| Scheduled production | Freshness, cardinality, critical invariants, scoped volume/drift and targeted honesty tests | Threshold breach with accountable recipient |
| Periodic review | Test inventory, flapping tests, cost, dead tests, exemptions and incident learnings | Chronic alert fatigue or unowned tests |

Keep the package and test harness separate from external live systems. For a future repo, pin package versions and audit transitive dependencies. For dbt 1.12, do **not** accidentally install dbt-project-evaluator v2, which requires dbt 2.

## 6. Adversarial checks before adoption

1. **Vacuous success:** Empty input passes key tests. Add a required-population check and a deliberately missing-table mutant.
2. **Test-configuration weakening:** Change true to quoted "false", alter bounds/where, then verify a reviewed configuration source lock or CI review detects it.
3. **Two wrongs agree:** Source and derived model both drop the same records, so their count comparison agrees. Check against an independent expectation or source inventory.
4. **Coincidentally equal sums:** Opposite-signed errors cancel. Reconcile keys/segments before aggregate totals.
5. **Duplicated facts:** Correct-looking group total from multiplied rows. Assert grain at input and after each risky join.
6. **Precision laundering:** Estimated date becomes exact-looking timestamp. Inspect labels, conversions and consumer text.
7. **Test induced privacy leak:** Enable stored failed rows on sensitive data. Confirm no actual private values reach logs or artifacts.
8. **Performance DoS:** Whole-table negative joins on billion-row facts. Require scope-aware benchmark and scheduled heavier checks.
9. **Monitoring without action:** A warning fires every day, but no one owns it. Replace repeated unactionable warnings with a documented ownership and threshold decision.
10. **Adapter mismatch:** Test works in DuckDB but has different SQL/metadata semantics in warehouse. Compile/run positive and negative fixtures on target adapter.

**Before a critical test is adopted:** Name the mistake it should catch; run valid and deliberately broken examples; ensure the target records are present; review whether failure messages can reveal private data; measure runtime; and identify the person who will respond.

## 7. Suggested starting plan

**First day:** Write down what one row means and who owns each of the top three consumer-facing models; add native tests and a SQL unit test for the riskiest transform; schedule source freshness; run a deliberately invalid fixture.

**First two weeks:** Add composite grain and row conservation to high-risk joins; historical correctness for SCDs; finance/metric reconciliation to an independent source; provenance labels where approximate data is used; benchmark and prune duplicated checks.

**Later:** Bring in schema and volume anomaly monitoring only after the simple contracts are stable and operational owners agree on alert actions. Avoid importing an entire framework because a catalog has hundreds of expectations.

## Version and reference notes

- Package contracts, edge cases and portability: [mutation matrix](CONTRACT_MUTATION_MATRIX.md), [adapter compatibility](ADAPTER_COMPATIBILITY.md), and [README](../README.md).
- Native [dbt data tests](https://docs.getdbt.com/docs/build/data-tests), [unit tests](https://docs.getdbt.com/docs/build/unit-tests), [freshness](https://docs.getdbt.com/docs/deploy/source-freshness); maintained [dbt-utils](https://github.com/dbt-labs/dbt-utils).
- Examples in this document have **not** been executed in a new target analytics repo. Adapt and validate with the dbt version/adapter and business requirements of that repo; the existing synthetic package CI does not validate these illustrative snippets.

## Runnable examples

Start with the [basic example project](../ae_starter/README.md)
when you want to **run** the standard testing patterns instead of only reading YAML. It includes a pinned `dbt-utils` dependency, honest and
deliberately corrupt fixtures, native SQL unit tests and safety refusals. Its smoke suite verifies DuckDB and PostgreSQL
without touching production. The surrounding `honest-data` package stays
independent and dependency-free.

**Exclusions and the advanced example.** Review the [decision register](AE_EXCLUSIONS_AND_DECISIONS.md) before installing packages: it documents the reasons we deliberately left out some otherwise useful tools, the triggers to revisit them, and the failure modes a test does not cover. The [advanced example project](../ae_advanced/README.md) exercises incremental replay, SCD-like history intervals and metric reconciliation independently of the baseline starter. Neither example project is a production deployment recipe.

---

[← README](../README.md) · [Case study](when-clean-data-lies.md) · [All docs](README.md)
