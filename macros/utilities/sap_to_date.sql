{%- macro sap_to_date(sap_date_value) -%}

    {{- adapter.dispatch('sap_to_date', 'sie_dbt_utils')(sap_date_value=sap_date_value) -}}

{%- endmacro %}

{% macro snowflake__sap_to_date(sap_date_value) %}to_char(to_date({{sap_date_value}}, 'YYYYMMDD')){% endmacro %}
