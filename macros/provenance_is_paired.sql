{#-
    provenance_is_paired
    ====================

    A value and its provenance label must be consistent. The test checks
    both directions: a value without a label and a label without a value.

    The defect it exists for: a column of inferred values that carries no
    nulls looks exactly like a column of measured ones. In the pipeline
    this pattern came from, 18,536 rows held a date derived from a
    relative string ("Posted 30+ Days Ago" -> now minus 30 days) with
    zero nulls among them. Without a precision label, downstream
    consumers could not distinguish estimates from observed dates.

    Two polarities, because the two real shapes are mirror images:

      label_when = 'value_present'   (a PRECISION label)
          posted_at_precision: exact | day_approximated | censored_floor
          Present exactly when posted_at is. A date with no precision
          label is indistinguishable from an exact one -- the original
          defect. A precision label with no date qualifies nothing.

      label_when = 'value_absent'    (an ABSENCE REASON)
          pay_absent_reason: not_disclosed | no_parser_for_source | ...
          Present exactly when pay_min is NULL. A bare null conflates two
          unrelated facts -- "the employer declined to publish a range"
          and "we cannot read pay from this source at all" -- and the
          difference matters both to a reader and to anyone measuring
          whether the pipeline is getting better.

    Both directions are asserted on purpose. A one-way implication can
    allow an absence reason to accompany a present value. This
    inconsistency can mislead downstream consumers.

    Args
    ----
    provenance_column   (required) the label column.
    label_when          'value_present' (default) | 'value_absent'.
    blank_provenance_is_missing  true by default. Empty or whitespace-only
                        labels are absent, not valid provenance. Set false
                        only for a documented legacy encoding; it does
                        NOT check whether a nonblank label is allowed.
    key_column          optional; echoed into the failure rows so a
                        failure names which rows are wrong, not just how
                        many.

    Usage
    -----
    models:
      - name: dim_jobs
        columns:
          - name: posted_at
            data_tests:
              - honest_data.provenance_is_paired:
                  arguments:
                    provenance_column: posted_at_precision
                    key_column: job_key
          - name: pay_min
            data_tests:
              - honest_data.provenance_is_paired:
                  arguments:
                    provenance_column: pay_absent_reason
                    label_when: value_absent
                    key_column: job_key

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test provenance_is_paired(model, column_name, provenance_column,
                             label_when='value_present', key_column=none,
                             blank_provenance_is_missing=true) %}

    {%- if label_when not in ['value_present', 'value_absent'] -%}
        {{ exceptions.raise_compiler_error(
            "honest_data.provenance_is_paired: label_when must be "
            ~ "'value_present' or 'value_absent', got '" ~ label_when ~ "'") }}
    {%- endif -%}

    {%- set key_expr = key_column if key_column else 'null' -%}

    {# Provenance represented as an empty string is not provenance. Cast to
       text only for the optional blank check so other non-string labels
       retain their original NULL semantics. #}
    {%- set blank_counts_as_missing = honest_data.boolean_argument(blank_provenance_is_missing, 'provenance_is_paired.blank_provenance_is_missing') -%}
    {% if blank_counts_as_missing %}
        {% set label_is_missing %}
        ({{ provenance_column }} is null
         or trim(cast({{ provenance_column }} as varchar)) = '')
        {% endset %}
    {% else %}
        {% set label_is_missing %}
        ({{ provenance_column }} is null)
        {% endset %}
    {% endif %}

    with rows_under_test as (
        select * from {{ model }}
    ),

    violations as (

    {% if label_when == 'value_present' %}

        select
            'value present without a provenance label' as failure,
            cast({{ key_expr }} as varchar) as failing_key,
            cast({{ column_name }} as varchar) as value_shown,
            cast({{ provenance_column }} as varchar) as provenance_shown
        from rows_under_test
        where {{ column_name }} is not null
          and {{ label_is_missing }}

        union all

        select
            'provenance label with no value to qualify',
            cast({{ key_expr }} as varchar),
            cast({{ column_name }} as varchar),
            cast({{ provenance_column }} as varchar)
        from rows_under_test
        where {{ column_name }} is null
          and not {{ label_is_missing }}

    {% else %}

        select
            'value absent with no reason given' as failure,
            cast({{ key_expr }} as varchar) as failing_key,
            cast({{ column_name }} as varchar) as value_shown,
            cast({{ provenance_column }} as varchar) as provenance_shown
        from rows_under_test
        where {{ column_name }} is null
          and {{ label_is_missing }}

        union all

        select
            'value present but an absence reason is set',
            cast({{ key_expr }} as varchar),
            cast({{ column_name }} as varchar),
            cast({{ provenance_column }} as varchar)
        from rows_under_test
        where {{ column_name }} is not null
          and not {{ label_is_missing }}

    {% endif %}

    )

    select * from violations

{% endtest %}
