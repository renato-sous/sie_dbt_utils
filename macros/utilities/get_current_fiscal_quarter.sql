{% macro get_current_fiscal_quarter() %}
    {{- return(adapter.dispatch('get_fiscal_quarter', 'sie_dbt_utils')(0)) -}}

{% endmacro %}

{% macro get_fiscal_quarter(_offset=0) %}
    {{- return(adapter.dispatch('get_fiscal_quarter', 'sie_dbt_utils')(_offset=_offset)) -}}
{% endmacro %}

{% macro default__get_fiscal_quarter(_offset=0) %}
{# /*
get_fiscal_quarter
    This macro returns the fiscal quarter based on the current timestamp and consider the offset given, as a integer number

# Parameters
    _offset (integer.) : This is the offset to the current fiscal quarter. Default value = 0

    -- Example showing to filter the values based on the current fiscal period and the 2 previous fiscal periods
    select *
    from {{ source('schema', 'table') }}
    where
        fiscal_period between '{{ sie_dbt_utils.get_fiscal_quarter(-2) }}' and '{{ sie_dbt_utils.get_fiscal_quarter() }}'
        
    (sql) -> where quarter between '1' and '2' -- assuming this was build on 2023.01.10
*/#}

    {% set fiscal_period=sie_dbt_utils.get_current_fiscal_period_date(_offset) %}
    {% set quarter=((fiscal_period.month -1)//3 + 1) %}    
    {{ return(quarter) }}
{% endmacro %}
