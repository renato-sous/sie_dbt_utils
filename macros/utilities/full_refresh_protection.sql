{# https://discourse.getdbt.com/t/how-to-prevent-accidental-full-refreshes-for-a-model/1008 #}
{%- macro full_refresh_protection() -%}
    {{- return(adapter.dispatch('full_refresh_protection', 'sie_dbt_utils')()) -}}
{%- endmacro %}


{% macro default__full_refresh_protection() -%}
    {% if execute %}
        {% if flags.FULL_REFRESH %}
            {{ exceptions.raise_compiler_error("Full refresh is not allowed for this model. Exclude it from the run via the argument \"--exclude "~ model.name ~"\"." ) }}
        {% endif %}
    {% endif %}
{%- endmacro %}  
