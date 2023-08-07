{%- macro add_workdays(__alias, __first_date, number_workdays) -%}

    {{- adapter.dispatch('add_workdays', 'sie_dbt_utils')(__alias=__alias, __first_date=__first_date, number_workdays=number_workdays) -}}

{%- endmacro %}

{% macro snowflake__add_workdays(__alias, __first_date, number_workdays) -%}
    (case 
        when {{ __first_date }} < {{ __alias }}.min_date then null
        when round({{ number_workdays }}) = 0 then {{ __first_date }}
        when round({{ number_workdays }}) > 0
            then dateadd('day', 
                     regexp_instr({{ __alias }}.workday_flags,
                                '1', 1+datediff('days', {{ __alias }}.min_date, date_trunc('day', {{ __first_date }})), 
                                {{ number_workdays }} + 1)-1  
                        , {{ __alias }}.min_date)
        else dateadd('day', 
                     -regexp_instr(reverse(substr({{ __alias }}.workday_flags, 1, datediff('days', {{ __alias }}.min_date, date_trunc('day', {{ __first_date }})))), --subject
                              '1', 1, abs({{ number_workdays }})) 
                        , {{ __first_date }})
    end)
{%- endmacro %}
