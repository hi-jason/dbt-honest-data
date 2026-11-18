{#-
  every_row_accounted_for
  =======================
  Checks equality of non-null key sets: every distinct source key appears
  exactly once in the derived model, and (unless allow_extra=true) there
  are no derived keys absent from the source.

  The source may contain repeated keys (e.g. multiple snapshots of one
  listing). This is KEY conservation, not source-row multiplicity. Use
  partitions_into for a split of unique input records. Both sides reject
  null keys, because SQL joins cannot reconcile them safely.

  Args:
    against: required source relation, preferably ref('source_model')
    key: key expression in the derived relation
    against_key: expression in the source; defaults to key
    row_filter, against_filter: optional WHERE expressions
    allow_extra: permit derived keys not in the source (default false)
    allow_duplicates: permit derived keys repeated within the model
                      (default false); does NOT compare multiplicities
    require_unique_source: optionally reject repeated source keys
                           (default false for snapshot/event sources)

  Key comparisons use native compatible SQL types (e.g. INTEGER and
  DECIMAL), rather than comparing formatted text. Keys from unrelated
  domains need explicit user-chosen normalization before this test.

  Important: WHERE filters define the key populations being compared.
  Where possible use dbt ref() for both sides so checks run after models.

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test every_row_accounted_for(model, against, key, against_key=none,
                                row_filter=none, against_filter=none,
                                allow_extra=false, allow_duplicates=false,
                                require_unique_source=false) %}
    {%- set there_key = against_key if against_key else key -%}
    {%- set permit_extra = honest_data.boolean_argument(allow_extra, 'every_row_accounted_for.allow_extra') -%}
    {%- set permit_duplicates = honest_data.boolean_argument(allow_duplicates, 'every_row_accounted_for.allow_duplicates') -%}
    {%- set source_unique = honest_data.boolean_argument(require_unique_source, 'every_row_accounted_for.require_unique_source') -%}

    with here as (
        select {{ key }} as k, count(*) as n
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
        group by 1
    ),
    there as (
        select {{ there_key }} as k, count(*) as n
        from {{ against }}
        {% if against_filter %}where {{ against_filter }}{% endif %}
        group by 1
    )

    select
        'in the source, missing here' as failure,
        cast(there.k as varchar) as failing_key,
        there.n as rows_in_source,
        cast(0 as bigint) as rows_here
    from there
    left join here on here.k = there.k
    where here.k is null and there.k is not null

    union all
    select
        'source row has a null identity',
        cast(null as varchar),
        there.n,
        cast(0 as bigint)
    from there
    where there.k is null

    union all
    select
        'derived row has a null identity',
        cast(null as varchar),
        cast(0 as bigint),
        here.n
    from here
    where here.k is null

    {% if not permit_extra %}
    union all
    select
        'here, but not in the source',
        cast(here.k as varchar),
        cast(0 as bigint),
        here.n
    from here
    left join there on there.k = here.k
    where there.k is null and here.k is not null
    {% endif %}

    {% if not permit_duplicates %}
    union all
    select
        'more than once here',
        cast(here.k as varchar),
        cast(null as bigint),
        here.n
    from here
    where here.n > 1 and here.k is not null
    {% endif %}

    {% if source_unique %}
    union all
    select
        'source key is duplicated',
        cast(there.k as varchar),
        there.n,
        cast(null as bigint)
    from there
    where there.n > 1 and there.k is not null
    {% endif %}
{% endtest %}
