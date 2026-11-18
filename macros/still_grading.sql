{#-
    still_grading
    =============

    The population a guard grades is not empty.

    A test that returns no rows passes. So does a test whose WHERE
    clause no longer matches anything: the source it watched was
    renamed, the filter's vocabulary changed, or the matching rows were
    quarantined upstream. Both situations can appear as passing tests
    even though the expected subset is no longer being assessed.

    Use this check alongside tests that assess a subset of a model,
    with the same filter. By default, it fails when the model has rows
    but the expected subset is empty.

    Args
    ----
    row_filter              (required) SQL boolean; the population the
                            sibling guard grades.
    min_rows                1 by default.
    only_when_model_has_rows
                            true by default: an empty model is a
                            different problem (assert row counts
                            separately) and does not fire this.

    Usage
    -----
    models:
      - name: dim_listings
        data_tests:
          - honest_data.still_grading:
              arguments:
                row_filter: "posted_at is not null and source in ('a', 'b')"

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test still_grading(model, row_filter, min_rows=1,
                      only_when_model_has_rows=true) %}

    {%- if min_rows < 1 or min_rows != (min_rows | int) -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.still_grading: min_rows must be a positive integer') }}
    {%- endif -%}

    {%- set ignore_empty_model = honest_data.boolean_argument(only_when_model_has_rows, 'still_grading.only_when_model_has_rows') -%}

    with counted as (
        select
            count(*) as model_rows,
            sum(case when {{ row_filter }} then 1 else 0 end) as graded_rows
        from {{ model }}
    )

    select
        'the graded population is empty, so its guard checks nothing' as failure,
        {{ honest_data.sql_literal(row_filter) }} as graded_population,
        model_rows,
        coalesce(graded_rows, 0) as graded_rows,
        {{ min_rows }} as min_rows
    from counted
    where coalesce(graded_rows, 0) < {{ min_rows }}
      {% if ignore_empty_model %}and model_rows > 0{% endif %}

{% endtest %}
