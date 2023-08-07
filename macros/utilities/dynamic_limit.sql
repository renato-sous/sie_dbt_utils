{% macro dynamic_limit() %}
    {{- return(adapter.dispatch('dynamic_limit', 'sie_dbt_utils')()) -}}
{% endmacro %}

{% macro snowflake__dynamic_limit() %}
   {{- return ( ( 'LIMIT ' ~  var("sdu_data_limit", '200') ~'/* This Limit was defined by sie_dbt_utils.dynamic_limit() */') if flags.WHICH != 'rpc' and (target.name == 'CI' or target.name == 'default' and  var("sdu_data_limit", -1) != -1 )) -}}
{% endmacro %}
