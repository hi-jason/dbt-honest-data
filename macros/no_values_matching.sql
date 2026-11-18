{#-
  no_values_matching
  ==================
  Look for denied LIKE patterns in text. This is a tripwire, not proof
  that a model contains no private data. Use explicit field allowlists and
  a column-name guard too.

  IMPORTANT PRIVACY BOUNDARIES:
  * Failure rows include ONLY rule IDs, field expressions and hit counts,
    never matched text or literal patterns.
  * The SQL itself necessarily contains pattern literals. Never configure
    this with actual PII, secrets, personal email addresses, or passwords.
    Use fictional canary tokens or safe pattern classes instead.
  * Auto-discovery scans ONLY adapter-declared STRING columns. JSON,
    arrays, nested structs, binary values and other serialized payloads
    may not be scanned. Pass columns: ['cast(payload as varchar)'] to
    include such fields explicitly, after verifying adapter compatibility.
  * With no text columns, compilation fails unless allow_no_columns=true.
  * For large tables, configure a small field list to control scan cost.

  Args:
    patterns: required LIKE patterns (not regex)
    rule_ids: optional stable NONSENSITIVE rule names, one per pattern;
              defaults to rule_1, rule_2, ...
    columns: optional SQL column names or expressions; otherwise scans
             discovered string columns
    row_filter: optional WHERE
    allow_no_columns: default false

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test no_values_matching(model, patterns, columns=none, row_filter=none,
                           allow_no_columns=false, rule_ids=none) %}
    {%- set permit_no_columns = honest_data.boolean_argument(allow_no_columns, 'no_values_matching.allow_no_columns') -%}
    {%- if not patterns -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.no_values_matching: patterns must be a non-empty list') }}
    {%- endif -%}
    {%- if rule_ids is not none and rule_ids | length != patterns | length -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.no_values_matching: rule_ids and patterns must have equal lengths') }}
    {%- endif -%}

    {%- set scan = [] -%}
    {%- if columns -%}
        {%- for c in columns -%}{%- do scan.append(c) -%}{%- endfor -%}
    {%- elif execute -%}
        {%- for col in adapter.get_columns_in_relation(model) -%}
            {%- if col.is_string() -%}{%- do scan.append(adapter.quote(col.name)) -%}{%- endif -%}
        {%- endfor -%}
    {%- endif -%}

    {%- if execute and scan | length == 0 and not permit_no_columns -%}
        {{ exceptions.raise_compiler_error(
            'honest_data.no_values_matching: no string columns found; specify columns or allow_no_columns: true') }}
    {%- endif -%}

    {% if scan | length == 0 %}
    -- parse-time/explicitly permitted empty selection
    select cast(null as varchar) as column_name,
           cast(null as varchar) as rule_id,
           cast(0 as bigint) as rows_matching,
           cast(null as varchar) as failure
    where 1 = 0
    {% else %}
    with scanned as (
        select
        {% for c in scan %}
            {% set outer = loop %}
            {% for p in patterns %}
                sum(case when lower(cast({{ c }} as varchar)) like lower({{ honest_data.sql_literal(p) }})
                         then 1 else 0 end) as hit_{{ outer.index }}_{{ loop.index }}
                {{ ',' if not (outer.last and loop.last) }}
            {% endfor %}
        {% endfor %}
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
    )

    {% for c in scan %}
        {% set outer = loop %}
        {% for p in patterns %}
            select
                {{ honest_data.sql_literal(c) }} as column_name,
                {{ honest_data.sql_literal(rule_ids[loop.index0] if rule_ids is not none else 'rule_' ~ loop.index) }} as rule_id,
                cast(hit_{{ outer.index }}_{{ loop.index }} as bigint) as rows_matching,
                'a denied value reached this model' as failure
            from scanned
            where hit_{{ outer.index }}_{{ loop.index }} > 0
            {% if not (outer.last and loop.last) %}union all{% endif %}
        {% endfor %}
    {% endfor %}
    {% endif %}
{% endtest %}
