{#-
    not_in_the_future
    =================

    A timestamp that says when something was observed cannot be later
    than now.

    A future-dated row can distort measures based on max(date). An invalid
    export timestamp can make other records appear stale, prevent
    subsequent updates, and weaken freshness checks.

    The default one-day grace period accounts for time-zone differences.
    It should still detect timestamps substantially ahead of observation
    time, such as a month or a year in the future.

    Args
    ----
    grace_days    1 by default. Days past now that are tolerated.
    key_column    optional; echoed so a failure names the row.
    row_filter    optional SQL boolean limiting the rows; grouped before AND.

    Usage
    -----
    models:
      - name: stg_exports
        columns:
          - name: export_date
            data_tests:
              - honest_data.not_in_the_future:
                  arguments:
                    key_column: export_id

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test not_in_the_future(model, column_name, grace_days=1, key_column=none,
                          row_filter=none) %}

    {%- set key_expr = key_column if key_column else 'null' -%}

    select
        'dated in the future' as failure,
        cast({{ key_expr }} as varchar) as failing_key,
        cast({{ column_name }} as varchar) as value_shown,
        {{ grace_days }} as grace_days
    from {{ model }}
    where {{ column_name }} is not null
      and cast({{ column_name }} as timestamp)
          > cast({{ dbt.dateadd('day', grace_days, dbt.current_timestamp()) }} as timestamp)
      {% if row_filter %}and ({{ row_filter }}){% endif %}

{% endtest %}
