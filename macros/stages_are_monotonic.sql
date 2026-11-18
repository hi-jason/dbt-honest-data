{#-
    stages_are_monotonic
    ====================

    Dates that describe a sequence must run in sequence: a later stage is
    never dated before an earlier one, and a bound is never past the
    thing it bounds.

    The failure this prevents is quiet by construction. A duration
    computed from two dates that run backwards is negative, and the usual
    defensive code turns a negative duration into NULL. The row then
    reads as "still in that stage" and drops out of every median, so the
    data-entry slip, the event attached to the wrong record, or the clock
    that disagreed is never seen by a person.

    The same test covers "a floor never exceeds what was observed": a
    lower bound on a date (first_possible_at) listed before the first
    sighting (first_seen_at) is a two-stage sequence.

    Each stage is compared with every EARLIER stage that is not null, so
    a skipped stage (straight from the first to the third) is no
    violation.

    Args
    ----
    stages        (required) columns or SQL expressions, earliest first.
    key_column    optional; echoed so a failure names the row.
    strict        false by default (equal is fine). true requires each
                  stage strictly after the earlier ones.
    row_filter    optional SQL boolean limiting the rows.

    Usage
    -----
    models:
      - name: order_lifecycle
        data_tests:
          - honest_data.stages_are_monotonic:
              arguments:
                stages: [placed_at, paid_at, shipped_at, delivered_at]
                key_column: order_id

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test stages_are_monotonic(model, stages, key_column=none, strict=false,
                             row_filter=none) %}

    {%- if not stages or stages | length < 2 -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.stages_are_monotonic: stages needs at least two columns, earliest first') }}
    {%- endif -%}

    {%- set key_expr = key_column if key_column else 'null' -%}
    {%- set require_strict = honest_data.boolean_argument(strict, 'stages_are_monotonic.strict') -%}
    {%- set op = '<=' if require_strict else '<' -%}

    with rows_under_test as (
        select * from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
    )

    {% set arms = [] %}
    {% for later in stages %}
      {% set j = loop.index0 %}
      {% for earlier in stages %}
        {% if loop.index0 < j %}
          {% do arms.append((earlier, later)) %}
        {% endif %}
      {% endfor %}
    {% endfor %}

    {% for earlier, later in arms %}
    select
        {{ honest_data.sql_literal(later ~ ' is before ' ~ earlier) }} as failure,
        cast({{ key_expr }} as varchar) as failing_key,
        cast({{ earlier }} as varchar) as earlier_value,
        cast({{ later }} as varchar) as later_value
    from rows_under_test
    where {{ earlier }} is not null
      and {{ later }} is not null
      and {{ later }} {{ op }} {{ earlier }}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}

{% endtest %}
