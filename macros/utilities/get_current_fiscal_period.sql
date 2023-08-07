{% macro get_current_fiscal_period() %}
    {{- return(adapter.dispatch('get_fiscal_period', 'sie_dbt_utils')(0)) -}}

{% endmacro %}

{% macro get_fiscal_period(_offset=0) %}
    {{- return(adapter.dispatch('get_fiscal_period', 'sie_dbt_utils')(_offset=_offset)) -}}
{% endmacro %}



{% macro default__get_fiscal_period(_offset = 0) %}
{# /*
get_current_fiscal_period
This macro returns the fiscal period based on the current timestamp and consider the offset given

# Parameters
    _offset (integer.) : This is the offset to the current fiscal period. Default value = 0

    -- Example showing to filter the values based on the current fiscal period and the 2 previous fiscal periods
    select *
    from {{ source('schema', 'table') }}
    where
        fiscal_period between '{{ sie_dbt_utils.get_current_fiscal_period(-2) }}' and '{{ sie_dbt_utils.get_current_fiscal_period() }}'

    (sql) -> where fiscal_period between '2023002' and '2023004'
*/#}
    {% set fiscal_period=sie_dbt_utils.get_current_fiscal_period_date(_offset) %}
    {{ return (fiscal_period.strftime('%Y0%m')) }}
{% endmacro %}


{# Internal Macros #}

{% macro get_current_fiscal_period_date(_offset = 0) %}
    {# This macro derives the Fiscal date and rturns as a jinja date #}
    {% set now = modules.datetime.date.today() %}
    {% set next_month = modules.datetime.timedelta(days=5) %}

    {# Get the current Fiscal Period #}
    {% set fiscal_period = ((now.replace(day=28)+next_month).replace(day=28)+next_month).replace(day=28)+next_month %}

    {# In case we have an offset. Derive it#}
    {% if _offset != 0 %}    
        {% set _step=((_offset|abs) / _offset) | int %}
        
        {% set half_month = modules.datetime.timedelta(days=(18 * _step)) %}
        {% set ns = namespace(fper=fiscal_period) %}

        {% for _off in range(_offset|abs) %}
            {% set ns.fper = ns.fper.replace(day=15) %}
            {% set ns.fper = (ns.fper + half_month) %}
        {%- endfor %}
        {% set fiscal_period = ns.fper %}
    {% endif %}
    {{ return(fiscal_period) }}    
{% endmacro %}
