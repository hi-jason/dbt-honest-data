{#-
    bounds_are_a_window
    ===================

    Some events are only ever observed between two points. A polling
    pipeline learns that a record changed by seeing it differ from last
    time -- which locates the change inside the interval between two
    reads, and nowhere more precise than that. One observed change in the
    corpus this came from is bounded to a five-day window. An exact
    timestamp would overstate the precision of those observations.

    So the schema has no changed_at column. It has changed_after and
    changed_before, and this test keeps that pair coherent: both
    populated, and strictly ordered.

    The design recommendation is to address the schema before adding tests.
    Dropping the point-in-time column came first; this test came second.
    A test can only catch a bad value in a column that is allowed to
    exist -- delete the column and the whole class of error is
    unreachable. The test then protects the replacement interval fields.

    Pair this with honest_data.column_name_denylist over a pattern like
    '%changed_at%' if you want the deleted column to stay deleted.
    Otherwise a future change could reintroduce a misleading timestamp
    without triggering an assertion.

    Args
    ----
    upper_column  (required) the later bound.
    allow_equal   false (default). A zero-width window means two reads at
                  the same instant bracketed a change, which is not
                  something a polling pipeline can observe. Set true only
                  if your source genuinely permits it.
    key_column    optional; echoed into failure rows.

    Usage
    -----
    models:
      - name: int_job_content_changes
        columns:
          - name: changed_after
            data_tests:
              - honest_data.bounds_are_a_window:
                  arguments:
                    upper_column: changed_before
                    key_column: job_key

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test bounds_are_a_window(model, column_name, upper_column,
                            allow_equal=false, key_column=none) %}

    {%- set key_expr = key_column if key_column else 'null' -%}
    {%- set permit_equal = honest_data.boolean_argument(allow_equal, 'bounds_are_a_window.allow_equal') -%}
    {%- set order_op = '>' if permit_equal else '>=' -%}

    select
        cast({{ key_expr }} as varchar) as failing_key,
        cast({{ column_name }} as varchar) as lower_bound,
        cast({{ upper_column }} as varchar) as upper_bound,
        case
            when {{ column_name }} is null and {{ upper_column }} is null
                then 'window has neither bound'
            when {{ column_name }} is null
                then 'window has no lower bound'
            when {{ upper_column }} is null
                then 'window has no upper bound'
            else 'window is not strictly ordered'
        end as failure
    from {{ model }}
    where {{ column_name }} is null
       or {{ upper_column }} is null
       or {{ column_name }} {{ order_op }} {{ upper_column }}

{% endtest %}
