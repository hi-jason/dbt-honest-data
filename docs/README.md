# Documentation

[← Back to the README](../README.md)

`dbt-honest-data` is a dbt testing package plus two small example projects. Read in this order, and stop wherever you have what you need.

| Order | Read | What it gives you |
| --- | --- | --- |
| 1 | [Main README](../README.md) | What the package is, the three headline findings, the checks, and CI results |
| 2 | [Case study: *When clean data lies*](when-clean-data-lies.md) | The six findings, how each was diagnosed, and the check each led to |
| 3 | [Testing playbook](AE_QUALITY_PLAYBOOK.md) | When dbt's built-in tests are enough, and when a specialized check is worth adding |
| 4 | [Decision register](AE_EXCLUSIONS_AND_DECISIONS.md) | Tools and checks deliberately not adopted, and what would change that |
| 5 | [How the tests are tested](../integration_tests/README.md) | The harness step by step, and every check's passing and planted-error fixtures |
| 6 | [Basic](../ae_starter/README.md) and [advanced](../ae_advanced/README.md) examples | Runnable projects with invented data |

**Reference:** [mutation matrix](CONTRACT_MUTATION_MATRIX.md) (the kinds of error each check targets) · [test pattern catalog](AE_TEST_PATTERN_CATALOG.md) (patterns and their assumptions) · [adapter compatibility](ADAPTER_COMPATIBILITY.md) (supported databases and versions) · [changelog](../CHANGELOG.md). The check code is in [`macros/`](../macros/).
