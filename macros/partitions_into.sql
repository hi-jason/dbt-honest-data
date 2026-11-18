{#-
  partitions_into
  ===============
  Exact partition contract at a unique non-null record-key grain.
  Every input key must be in exactly one part, each part key must belong to
  the filtered input population, and each part holds any key only once.

  Rejects duplicates and nulls in BOTH input and parts. If a row has
  multiple legitimate occurrences, supply a composite occurrence key (or
  create one first); this contract intentionally does not collapse rows
  with DISTINCT.

  Args:
    parts: list of ref() relations
    key: input key SQL expression
    part_key: same expression for all parts (default key)
    row_filter: optional WHERE for input ONLY. Outputs must already be
                scoped to this population; unexpected keys in a part FAIL.
                For general scoped output, create filtered part models.

  Keys are compared in native compatible SQL types (e.g. INTEGER and
  DECIMAL), not formatted strings. Use a shared key domain; mixed
  text/numeric or otherwise incompatible types are not supported.

  Cost: aggregates/hashes all input and part keys. A large production
  pipeline may prefer a separately proven count identity + small-set
  exception checks. Benchmark before replacing a specialized guard.

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test partitions_into(model, parts, key, part_key=none, row_filter=none) %}
    {%- if not parts -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.partitions_into: parts must be a non-empty list') }}
    {%- endif -%}
    {%- set pkey = part_key if part_key else key -%}

    with input_counts as (
        select {{ key }} as k, count(*) as n
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
        group by 1
    ),
    part_counts as (
        {% for part in parts %}
        select {{ pkey }} as k,
               {{ loop.index }} as part_no,
               count(*) as n
        from {{ part }}
        group by 1
        {% if not loop.last %}union all{% endif %}
        {% endfor %}
    ),
    placed as (
        select k, count(*) as parts_holding
        from part_counts
        group by 1
    )

    select
        'input key is missing from all parts' as failure,
        cast(i.k as varchar) as failing_key,
        cast(null as integer) as part_no,
        i.n as row_count
    from input_counts i
    left join placed p on p.k = i.k
    where i.k is not null and p.k is null

    union all
    select 'input contains a null key', cast(null as varchar),
           cast(null as integer), i.n
    from input_counts i
    where i.k is null

    union all
    select 'input key occurs more than once', cast(i.k as varchar),
           cast(null as integer), i.n
    from input_counts i
    where i.k is not null and i.n > 1

    union all
    select 'part contains a null key', cast(null as varchar),
           p.part_no, p.n
    from part_counts p
    where p.k is null

    union all
    select 'part key occurs more than once', cast(p.k as varchar),
           p.part_no, p.n
    from part_counts p
    where p.k is not null and p.n > 1

    union all
    select 'key appears in multiple parts', cast(p.k as varchar),
           cast(null as integer), p.parts_holding
    from placed p
    where p.k is not null and p.parts_holding > 1

    union all
    select 'part contains key outside the input population', cast(p.k as varchar),
           p.part_no, p.n
    from part_counts p
    left join input_counts i on i.k = p.k
    where p.k is not null and i.k is null
{% endtest %}
