{%- macro check_db_connection() -%}

    {{- adapter.dispatch('check_db_connection', 'sie_dbt_utils')() -}}

{%- endmacro %}

{% macro snowflake__check_db_connection() %}
    {% set _result = run_query("select current_timestamp() as timestmp, 'Query reached db successfully' as db_message, current_user() as db_user_name, current_ip_address() as ip_address") %}

    {{ log(' :: sie_dbt_utils.check_db_connection: ' ~ _result.rows[0][2]  ~ '(' ~ _result.rows[0][3] ~ '): ' ~ _result.rows[0][1] ~ ' [' ~  _result.rows[0][0] ~ '] ', info=True) }}
{% endmacro %}
