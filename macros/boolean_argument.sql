{#-
  Normalize booleans in data-integrity test contracts.

  Jinja truthiness does not parse boolean strings: "false" is truthy.
  A setting such as allow_duplicates: "false" could therefore disable
  an integrity check unexpectedly.
  Use this helper when test behavior depends on a boolean argument.

  Accepted tokens are case-insensitive:
    true / false, 1 / 0, yes / no, on / off.
  Unknowns (including null, empty, typo, 2, auto) raise a deliberate
  compiler error. Do not use Python's or Jinja's bare truthiness.
-#}
{% macro boolean_argument(value, option_name) %}
    {%- set token = value | string | trim | lower -%}
    {%- if token in ['true', '1', 'yes', 'on'] -%}
        {% do return(true) %}
    {%- elif token in ['false', '0', 'no', 'off'] -%}
        {% do return(false) %}
    {%- else -%}
        {{ exceptions.raise_compiler_error(
          'honest_data: boolean option ' ~ option_name
          ~ ' must be true/false, 1/0, yes/no, or on/off') }}
    {%- endif -%}
{% endmacro %}
