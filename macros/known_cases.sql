{#-
    known_cases
    ===========

    A small set of manually reviewed reference cases, checked on every build
    to detect regressions.

    A classifier, parser or normalizer may lack complete reference labels,
    so aggregate rates alone may not reveal regressions. Reviewed cases
    target specific examples, including ambiguous titles and identifiers
    whose URL parameters must be retained.

    Important false-pass condition: an inner join against reference cases
    can return no rows when a pinned key disappears, so the test passes
    silently. This test instead fails on missing
    cases by default, including cases removed by filters or renaming.

    Args
    ----
    key_column           (required) column (or SQL expression) that
                         identifies a case's row.
    value_column         (required) column (or expression) whose value is
                         pinned.
    cases                (required) list of {key: ..., expect: ...}.
                         `expect: null` pins a null. Each pin is compared
                         by its YAML type: a number numerically (so 15
                         matches 15.00), true/false as a boolean, anything
                         else as text. A numeric pin needs a value_column
                         that casts to a number.
    missing_is_failure   true by default. See above before turning it off.
    Pinned keys must be non-null and unique. A pinned key matching two
    actual rows FAILS even when both values agree with the expectation.
    Failure output may echo case keys and values; do not pin PII or secrets.
    row_filter           optional SQL boolean limiting the model's rows.

    Usage
    -----
    models:
      - name: classified_titles
        data_tests:
          - honest_data.known_cases:
              arguments:
                key_column: title
                value_column: role_family
                cases:
                  - {key: "Data Analyst", expect: "analyst"}
                  - {key: "Head of Data", expect: "leadership"}

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test known_cases(model, key_column, value_column, cases,
                    missing_is_failure=true, row_filter=none) %}

    {%- if not cases -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.known_cases: cases must be a non-empty list of {key, expect}') }}
    {%- endif -%}

    {# An omitted key cannot be matched, and a missing expected value could
       silently be interpreted as the intentional expect: null case. #}
    {%- for c in cases -%}
        {%- if 'key' not in c or c['key'] is none -%}
            {{ exceptions.raise_compiler_error(
                'honest_data.known_cases: every pinned case needs a non-null key') }}
        {%- endif -%}
        {%- if 'expect' not in c -%}
            {{ exceptions.raise_compiler_error(
                'honest_data.known_cases: every case must specify expect (null is allowed)') }}
        {%- endif -%}
    {%- endfor %}

    {%- set fail_missing = honest_data.boolean_argument(missing_is_failure, 'known_cases.missing_is_failure') -%}

    {#- Compare each pin by its own type. A text-only comparison would
        render a numeric(12,2) value 15.00 as '15.00' against a pinned 15,
        and a YAML true as 'True' against the database's 'true': correct
        data would fail. -#}
    {%- set ns = namespace(any_number=false) -%}
    {%- for c in cases -%}
        {%- set v = c['expect'] -%}
        {%- if v is number and not (v is sameas true or v is sameas false) -%}
            {%- set ns.any_number = true -%}
        {%- endif -%}
    {%- endfor %}

    with pinned as (
        {% for c in cases %}
        {%- set v = c['expect'] -%}
        {%- if v is sameas true or v is sameas false -%}
            {%- set kind = 'boolean' -%}
            {%- set expected_sql = "'true'" if v else "'false'" -%}
        {%- elif v is number -%}
            {%- set kind = 'number' -%}
            {%- set expected_sql = honest_data.sql_literal(v) -%}
        {%- else -%}
            {%- set kind = 'text' -%}
            {%- set expected_sql = honest_data.sql_literal(v) -%}
        {%- endif %}
        select
            cast({{ honest_data.sql_literal(c['key']) }} as varchar) as case_key,
            cast({{ expected_sql }} as varchar) as expected,
            cast('{{ kind }}' as varchar) as expect_kind
            {%- if ns.any_number %},
            cast({{ v if kind == 'number' else 'null' }} as decimal(38, 9)) as expected_number
            {%- endif %}
        {% if not loop.last %}union all{% endif %}
        {% endfor %}
    ),

    actual as (
        select
            cast({{ key_column }} as varchar) as case_key,
            cast({{ value_column }} as varchar) as got
            {%- if ns.any_number %},
            cast({{ value_column }} as decimal(38, 9)) as got_number
            {%- endif %}
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
    )

    select
        'pinned case has the wrong value' as failure,
        p.case_key,
        p.expected,
        a.got
    from pinned p
    join actual a on a.case_key = p.case_key
    where (a.got is null and p.expected is not null)
       or (a.got is not null and p.expected is null)
       or (p.expect_kind = 'text' and a.got <> p.expected)
       or (p.expect_kind = 'boolean' and lower(a.got) <> p.expected)
       {%- if ns.any_number %}
       or (p.expect_kind = 'number' and a.got_number <> p.expected_number)
       {%- endif %}

    {% if fail_missing %}
    union all

    select
        'pinned case is not in the model, so it is no longer checked',
        p.case_key,
        p.expected,
        cast(null as varchar)
    from pinned p
    left join actual a on a.case_key = p.case_key
    where a.case_key is null
    {% endif %}

    union all

    -- A pinned key with two actual rows is NOT an unambiguous answer,
    -- even if both rows happen to agree with the expected label.
    select
        'pinned key matches more than one actual row',
        p.case_key,
        cast(null as varchar),
        cast(count(*) as varchar)
    from pinned p
    join actual a on a.case_key = p.case_key
    group by p.case_key
    having count(*) > 1

    union all

    -- Two definitions for the same pinned key are a broken test contract.
    select
        'pinned key is declared more than once',
        p.case_key,
        cast(null as varchar),
        cast(count(*) as varchar)
    from pinned p
    group by p.case_key
    having count(*) > 1

{% endtest %}
