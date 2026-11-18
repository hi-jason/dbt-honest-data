{#-
    declared_rate_band
    ==================

    A broad claim that data is 'good' needs measurable criteria. This test
    asks a narrower question: does the observed population rate agree
    with the stated expectations for the field?

    So: every column that matters declares what it is --

        measured                a source told us this, directly
        derived                 computed from measured inputs
        approximated            inferred; carries a precision label
        defaulted_when_unknown  a stand-in value where we do not know
        absent_by_design        deliberately not populated here

    -- plus the rate at which it is actually populated. This test
    measures the real rate on every build and fails when it leaves the
    declared band. A field described as 'measured' but populated 42%
    from defaults does not meet the documented expectation.

    It can also detect source drift. When an upstream API stops sending a
    field, rows may continue to arrive while the populated share falls.
    A measured rate outside the declared band fails the affected build.

    Scope: documenting a band for every field can create unnecessary
    maintenance and alert noise. Prioritize fields with uncertainty,
    sentinel defaults, or ambiguous values (for example, a score of
    zero that may mean either 'scored zero' or 'no signal available').

    Set the band from measured reality plus deliberate slack, not from a
    round number that felt right. A band nobody can justify gets widened
    the first time it fails, which is the same as not having one.

    Args
    ----
    min_rate          (required) lower bound, 0..1 inclusive.
    max_rate          1.0 by default. Worth setting below 1.0 when
                      TOO MUCH coverage is itself the signal -- an
                      approximated column that suddenly reads 100%
                      populated usually means a fallback became the rule.
    epistemic_status  optional label, echoed in the failure so the
                      failure names the broken promise.
    measured_when     optional SQL boolean; what counts as genuinely
                      populated. Defaults to "<column> is not null".
                      Override it where the sentinel is a value rather
                      than a null, e.g. "completeness_score <> 0".
    row_filter        optional SQL boolean restricting which rows the
                      claim covers.
    fail_on_empty     false by default. An empty relation cannot falsify
                      a rate claim, so this stays silent rather than
                      firing on every fresh build -- assert row counts
                      separately. Set true if empty is itself a defect.

    Usage
    -----
    models:
      - name: dim_jobs
        columns:
          - name: posted_at
            data_tests:
              - honest_data.declared_rate_band:
                  arguments:
                    epistemic_status: approximated
                    min_rate: 0.95
          - name: completeness_score
            data_tests:
              - honest_data.declared_rate_band:
                  arguments:
                    epistemic_status: derived
                    measured_when: "completeness_score <> 0"
                    min_rate: 0.20

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test declared_rate_band(model, column_name, min_rate, max_rate=1.0,
                           epistemic_status=none, measured_when=none,
                           row_filter=none, fail_on_empty=false) %}

    {%- if min_rate < 0 or max_rate > 1 or min_rate > max_rate -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.declared_rate_band: require 0 <= min_rate <= max_rate <= 1') }}
    {%- endif -%}

    {%- set fail_empty = honest_data.boolean_argument(fail_on_empty, 'declared_rate_band.fail_on_empty') -%}
    {%- set populated = measured_when if measured_when
                        else column_name ~ ' is not null' -%}

    with counted as (
        select
            count(*) as total_rows,
            sum(case when {{ populated }} then 1 else 0 end) as populated_rows
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
    ),

    rated as (
        select
            total_rows,
            populated_rows,
            case when total_rows = 0 then null
                 else populated_rows * 1.0 / total_rows
            end as measured_rate
        from counted
    )

    select
        {{ honest_data.sql_literal(column_name) }} as column_under_test,
        {{ honest_data.sql_literal(epistemic_status) }} as declared_status,
        {{ honest_data.sql_literal(populated) }} as counted_as_populated,
        measured_rate,
        {{ min_rate }} as declared_min_rate,
        {{ max_rate }} as declared_max_rate,
        total_rows,
        populated_rows,
        case
            when total_rows = 0
                then 'no rows, so the declared rate could not be checked'
            when measured_rate < {{ min_rate }}
                then 'populated less often than declared'
            else 'populated more often than declared'
        end as failure
    from rated
    where
        {% if fail_empty %}
        total_rows = 0 or
        {% endif %}
        (total_rows > 0
         and (measured_rate < {{ min_rate }} or measured_rate > {{ max_rate }}))

{% endtest %}
