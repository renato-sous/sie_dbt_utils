{%- macro current_environment() -%}
    {{- return(adapter.dispatch('current_environment', 'sie_dbt_utils')()) -}}
{%- endmacro %}

{%- macro snowflake__current_environment() %}
    {{- return(target.database[:3]) }}
{%- endmacro %}
