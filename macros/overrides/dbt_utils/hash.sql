{# This override will ensure that the dbt_utils.surrogate_key macro will be using the `md5_binary` function instead of the `md5` function #}
{% macro snowflake__hash(field) -%}
    md5_binary(cast({{field}} as varchar))
{%- endmacro %}
