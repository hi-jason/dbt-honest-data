{#-
    Renders a Python/Jinja string as a single-quoted SQL literal with
    embedded quotes doubled.

    Several tests in this package echo their own arguments back in the
    failure rows -- a failure that says WHICH claim broke is worth far
    more than one that says a count. Those arguments are author-written
    strings that routinely contain apostrophes, so they cannot be
    interpolated raw.
-#}

{% macro sql_literal(value) -%}
    {%- if value is none -%}
        null
    {%- else -%}
        '{{ value | string | replace("'", "''") }}'
    {%- endif -%}
{%- endmacro %}
