{#-
    column_name_denylist / no_column_names_matching
    ===============================================

    Fails if a column whose NAME matches a denied pattern appears where
    it must not. Two forms, and the difference between them is the whole
    point:

      no_column_names_matching  -- a generic test, attached to one model
                                   in schema.yml.
      column_name_denylist      -- a macro for a singular test, scanning
                                   a WHOLE SCHEMA.

    Prefer the schema-wide form when the confidentiality boundary covers
    a whole schema, including new models. The per-model form is useful
    when the policy intentionally applies to one model. Select the form
    based on the actual boundary being protected.

    Limitations of a successful name-based scan:

    It matches column names against denied patterns. It cannot detect
    sensitive data under a different name. A pass confirms only that
    this name-based check found no matching columns. The primary
    safeguard is an explicit output allowlist; this test helps detect
    unintended additions to that allowlist.

    Args (no_column_names_matching)
    ------------------------------
    patterns  (required) list of SQL LIKE patterns, matched
              case-insensitively against column names.

    Args (column_name_denylist)
    ---------------------------
    patterns        (required) list of SQL LIKE patterns.
    schema          (required) schema to scan.
    database        optional; restricts the scan to one catalog.
    include_tables  optional; scan ONLY these tables; every named table
                    must exist or the test fails (including partial loss).
                    Prefer omitting it unless scoping is intentional.
    exclude_tables  optional; scan everything except these. Each entry
                    here is a standing exception and deserves a comment
                    saying why.
    required_tables optional; require each named table to exist WITHOUT
                    limiting the scan to only those names. Useful when
                    the schema must include key export models.

    Usage
    -----
    # tests/assert_no_internal_columns_in_reporting_schema.sql
    {{ honest_data.column_name_denylist(
         schema='main',
         patterns=['%internal_note%', '%secret_payload%']) }}

    By default both forms fail if the scan finds ZERO columns (missing
    schema, misspelled model or include_tables excluding everything).
    The escape hatch fail_when_empty=false requires a documented reason.
    This is a metadata-existence check, not proof an entire exported schema
    was rebuilt before the singular test ran: use ref() dependencies in
    the calling singular test or explicit build order.

    models:
      - name: dim_order_summary
        data_tests:
          - honest_data.no_column_names_matching:
              arguments:
                patterns: ['%internal_note%', '%secret_payload%']

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% macro _denied_column_predicate(patterns) -%}
    (
    {%- for pattern in patterns %}
        lower(column_name) like lower({{ honest_data.sql_literal(pattern) }})
        {%- if not loop.last %} or {% endif %}
    {%- endfor %}
    )
{%- endmacro %}


{% macro column_name_denylist(patterns, schema, database=none,
                              include_tables=none, exclude_tables=none,
                              fail_when_empty=true, required_tables=none) %}

    {%- if not patterns -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.column_name_denylist: patterns must be a non-empty list') }}
    {%- endif -%}

    {%- set enforce_nonempty = honest_data.boolean_argument(
        fail_when_empty, 'column_name_denylist.fail_when_empty') -%}

    {# An explicit include list is a requirement, not merely a filter.
       Otherwise [existent, missing] silently checks the surviving table.
       required_tables also protects critical objects without restricting
       the schema-wide scan to those objects. #}
    {%- set expected_tables = [] -%}
    {%- for t in include_tables or [] -%}
        {%- if t not in expected_tables -%}{%- do expected_tables.append(t) -%}{%- endif -%}
    {%- endfor -%}
    {%- for t in required_tables or [] -%}
        {%- if t not in expected_tables -%}{%- do expected_tables.append(t) -%}{%- endif -%}
    {%- endfor -%}

    with scoped_columns as (
        select table_schema, table_name, column_name
        from information_schema.columns
        where lower(table_schema) = lower({{ honest_data.sql_literal(schema) }})
          {%- if database %}
          and lower(table_catalog) = lower({{ honest_data.sql_literal(database) }})
          {%- endif %}
          {%- if include_tables %}
          and lower(table_name) in (
              {%- for t in include_tables -%}
              lower({{ honest_data.sql_literal(t) }}){{ ', ' if not loop.last }}
              {%- endfor -%}
          )
          {%- endif %}
          {%- if exclude_tables %}
          and lower(table_name) not in (
              {%- for t in exclude_tables -%}
              lower({{ honest_data.sql_literal(t) }}){{ ', ' if not loop.last }}
              {%- endfor -%}
          )
          {%- endif %}
    )
    select
        table_schema,
        table_name,
        column_name,
        'a denied column name reached this schema' as failure
    from scoped_columns
    where {{ honest_data._denied_column_predicate(patterns) }}

    {% if enforce_nonempty %}
    union all
    select
        {{ honest_data.sql_literal(schema) }} as table_schema,
        cast(null as varchar) as table_name,
        cast(null as varchar) as column_name,
        'schema column scan found no columns; the guard checked nothing' as failure
    where not exists (select 1 from scoped_columns)
    {% endif %}

    {% if expected_tables %}
    union all
    {% for expected_table in expected_tables %}
    select
        {{ honest_data.sql_literal(schema) }} as table_schema,
        {{ honest_data.sql_literal(expected_table) }} as table_name,
        cast(null as varchar) as column_name,
        'an explicitly required table was absent from the metadata scan' as failure
    where not exists (
        select 1 from scoped_columns
        where lower(table_name) = lower({{ honest_data.sql_literal(expected_table) }})
    )
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
    {% endif %}

{% endmacro %}


{% test no_column_names_matching(model, patterns, fail_when_empty=true) %}

    {%- if not patterns -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.no_column_names_matching: patterns must be a non-empty list') }}
    {%- endif -%}

    {%- set enforce_nonempty = honest_data.boolean_argument(
        fail_when_empty, 'no_column_names_matching.fail_when_empty') -%}

    with target_columns as (
        select table_schema, table_name, column_name
        from information_schema.columns
        where lower(table_schema) = lower({{ honest_data.sql_literal(model.schema) }})
          and lower(table_name) = lower({{ honest_data.sql_literal(model.identifier) }})
    )
    select
        table_schema,
        table_name,
        column_name,
        'a denied column name reached this model' as failure
    from target_columns
    where {{ honest_data._denied_column_predicate(patterns) }}

    {% if enforce_nonempty %}
    union all
    select
        {{ honest_data.sql_literal(model.schema) }} as table_schema,
        {{ honest_data.sql_literal(model.identifier) }} as table_name,
        cast(null as varchar) as column_name,
        'model column scan found no columns; the guard checked nothing' as failure
    where not exists (select 1 from target_columns)
    {% endif %}

{% endtest %}
