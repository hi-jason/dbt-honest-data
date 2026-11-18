{#-
    grouped_share_in_band
    =====================

    Per group, the share of rows meeting a condition stays inside a
    declared band.

    declared_rate_band checks a single population rate. A pooled rate may
    hide material differences across groups. A single broad band (say
    0.05–0.70) cannot distinguish a change in the denominator, a sudden
    increase in held records, or a rule that stopped matching.
    Group-specific bands make these changes easier to investigate.

    Two failure directions are important: a rising share may indicate a
    rule firing too often, while a declining share may indicate a rule
    that no longer detects intended cases.

    Args
    ----
    condition         (required) SQL boolean; the numerator.
    group_by          (required) column or SQL expression; one share per
                      distinct value.
    min_share         0.0 by default.
    max_share         1.0 by default.
    min_group_rows    1 by default. Groups smaller than this are not
                      graded because very small groups may have unstable rates.
    row_filter        optional SQL boolean; the denominator's rows.
                      Choose it deliberately: "rows open now" and "every
                      row ever written" give different alarms.
    Invalid bands or min_group_rows values raise a compile error.
    fail_when_nothing_graded
                      false by default. true fails when no group reaches
                      min_group_rows, so the alarm cannot go quiet by
                      running out of things to grade.

    Usage
    -----
    models:
      - name: listing_quarantine_status
        data_tests:
          - honest_data.grouped_share_in_band:
              arguments:
                condition: "is_held"
                group_by: source
                max_share: 0.10
                min_group_rows: 50

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test grouped_share_in_band(model, condition, group_by, min_share=0.0,
                              max_share=1.0, min_group_rows=1,
                              row_filter=none, fail_when_nothing_graded=false) %}

    {%- if min_share < 0 or max_share > 1 or min_share > max_share -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.grouped_share_in_band: require 0 <= min_share <= max_share <= 1') }}
    {%- endif -%}
    {%- if min_group_rows < 1 or min_group_rows != (min_group_rows | int) -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.grouped_share_in_band: min_group_rows must be a positive integer') }}
    {%- endif -%}

    {%- set require_grading = honest_data.boolean_argument(fail_when_nothing_graded, 'grouped_share_in_band.fail_when_nothing_graded') -%}

    with grouped as (
        select
            cast({{ group_by }} as varchar) as group_value,
            count(*) as group_rows,
            sum(case when {{ condition }} then 1 else 0 end) as rows_meeting
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
        group by 1
    ),

    graded as (
        select
            group_value,
            group_rows,
            rows_meeting,
            rows_meeting * 1.0 / group_rows as measured_share
        from grouped
        where group_rows >= {{ min_group_rows }}
    )

    select
        case when measured_share < {{ min_share }}
             then 'share below its declared floor'
             else 'share above its declared ceiling' end as failure,
        group_value,
        group_rows,
        rows_meeting,
        measured_share,
        {{ min_share }} as declared_min_share,
        {{ max_share }} as declared_max_share
    from graded
    where measured_share < {{ min_share }}
       or measured_share > {{ max_share }}

    {% if require_grading %}
    union all

    select
        'no group is large enough to grade, so this alarm cannot fire',
        cast(null as varchar),
        cast(0 as bigint),
        cast(0 as bigint),
        cast(null as double precision),
        {{ min_share }},
        {{ max_share }}
    from (select count(*) as graded_groups from graded) as g
    where g.graded_groups = 0
    {% endif %}

{% endtest %}
