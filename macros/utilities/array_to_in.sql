{% macro array_to_in(array=none) %}
{#
This macro will deliver a string with the list of values in a SQL IN format.
Sometimes in Jinja we have a list of values that we would like to apply directly to the SQL Queries, and this macro converts it easily.

 Parameters:
    - array array(string): array with the values to be filtered

Examples :
    {%set my_arr = ['ABCD', 'EFGH'] }}
    WHERE BUKRS in {{ sie_dbt_utils.array_to_in(my_arr)}}
    --> WHERE BUKRS in ('ABCD', 'EFGH')
#}
    {% if array is none %}
        {{ exceptions.raise_compiler_error("Invalid call to `sie_dbt_utils.array_to_in`: must provide a `array` value.") }}
    {% endif %}
    {{ return( "('" ~ ( array | map("replace", "'", "''") | join("','")) ~"')") }}
{% endmacro %}
