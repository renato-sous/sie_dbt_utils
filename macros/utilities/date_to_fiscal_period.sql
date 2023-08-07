{%- macro date_to_fiscal_period(date_value, out_format='yyyy0mm') -%}

    {{- adapter.dispatch('date_to_fiscal_period', 'sie_dbt_utils')(date_value=date_value, out_format=out_format) -}}

{%- endmacro %}

{% macro default__date_to_fiscal_period(date_value,out_format='yyyy0mm') %}to_char(add_months({{date_value}},3),'{{out_format}}'){% endmacro %}

{# short form: to_fiscper #}
{%- macro to_fiscper(date_value, out_format='yyyy0mm') -%}

    {{- adapter.dispatch('date_to_fiscal_period', 'sie_dbt_utils')(date_value=date_value, out_format=out_format) -}}

{%- endmacro %}
