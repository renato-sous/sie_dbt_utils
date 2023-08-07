{%- macro sap_to_timestamp(date_value, time_value=none) -%}
    {{- adapter.dispatch('sap_to_timestamp', 'sie_dbt_utils')(date_value, time_value) -}}
{%- endmacro %}


{% macro snowflake__sap_to_timestamp(date_value, time_value) %}
    {%- if time_value is none-%}
        try_to_timestamp({{date_value}},'yyyymmdd')
    {%- else -%}
        try_to_timestamp({{date_value}}||{{time_value}},'yyyymmddhh24miss')
    {%- endif -%}
{% endmacro %}
