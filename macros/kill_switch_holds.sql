{#-
    kill_switch_holds
    =================

    When a feature's switch is OFF, none of its rows are in this model.

    The disabled state of a feature may be exercised infrequently. This
    check verifies that turning the feature off removes its rows from
    the downstream model.

    By design, the test does not assert behavior while the switch is on.
    It checks the disabled state on the build where the switch turns
    off. If source history must be retained, a switch can exclude rows
    from downstream models without deleting the underlying records.

    Args
    ----
    switch_on     (required) the switch, as a boolean. Usually a var:
                  "{{ var('partner_feed_enabled') }}".
                  (Not named `enabled`: dbt reads an argument of that
                  name as the test's own enabled config and never passes
                  it to the macro, which would make every switch
                  read as off.)
    row_filter    optional SQL boolean naming the feature's rows in this
                  model. Default: every row (the model exists only for
                  the feature).
    key_column    optional; echoed so a failure names the rows.
    Invalid switch values raise a compile error instead of silently
    defaulting to OFF. To test OFF, pass false/0/off/no explicitly.

    Usage
    -----
    models:
      - name: dim_listings
        data_tests:
          - honest_data.kill_switch_holds:
              arguments:
                switch_on: "{{ var('partner_feed_enabled') }}"
                row_filter: "source = 'partner_feed'"
                key_column: listing_id

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test kill_switch_holds(model, switch_on, row_filter=none, key_column=none) %}

    {%- set key_expr = key_column if key_column else 'null' -%}
    {# Unknown switch values raise a compile error instead of silently
       acting like OFF, which would make this assertion misleading. #}
    {%- set is_on = honest_data.boolean_argument(switch_on, 'kill_switch_holds.switch_on') -%}

    select
        'present while its switch is off' as failure,
        cast({{ key_expr }} as varchar) as failing_key
    from {{ model }}
    where
        {% if is_on %}
        -- the switch is on: this test grades only the off position
        1 = 0
        {% else %}
        {{ row_filter if row_filter else '1 = 1' }}
        {% endif %}

{% endtest %}
