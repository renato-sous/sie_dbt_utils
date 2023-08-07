{% macro workdays_between(__alias, __first_date, __second_date) -%}
case
    when {{ __first_date }} > to_date('31-12-2100', 'DD-MM-YYYY') or {{ __second_date }} > to_date('31-12-2100', 'DD-MM-YYYY') then NULL
    when date_trunc('day',{{ __first_date }}) <= date_trunc('day',{{ __second_date }}) then
        length(replace(substr(
            {{ __alias }}.workday_flags,
            datediff('days',{{ __alias }}.min_date,date_trunc('day',{{ __first_date }}))+1,
            datediff('days',date_trunc('day',{{ __first_date }}),date_trunc('day',{{ __second_date }}))
        ),'0'))
    when date_trunc('day',{{ __first_date }}) > date_trunc('day',{{ __second_date }}) then
        -length(replace(substr(
            {{ __alias }}.workday_flags,
            datediff('days',{{ __alias }}.min_date,date_trunc('day',{{ __second_date }}))+1,
            datediff('days',date_trunc('day',{{ __second_date }}),date_trunc('day',{{ __first_date }}))
        ),'0'))
    else null
end
{%- endmacro %}
