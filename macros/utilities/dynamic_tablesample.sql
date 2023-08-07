{% macro dynamic_tablesample() %}
    {{- return(adapter.dispatch('dynamic_tablesample', 'sie_dbt_utils')()) -}}
{% endmacro %}

{% macro snowflake__dynamic_tablesample() %}
   {{- return ( ( 'tablesample (' ~  var("sdu_data_sample", '1') ~') /* This Limit was defined by sie_dbt_utils.dynamic_tablesample() (value is in percentage!) */') if flags.WHICH != 'rpc' and (target.name == 'CI' or target.name == 'default' and  var("sdu_data_sample", -1) != -1 )) -}}
{% endmacro %}
