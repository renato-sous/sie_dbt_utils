{% macro default__create_schema(relation) -%}
{# { log("#sie_dbt_utilsOVERRIDE schema.sql: default__create_schema" ~ relation.without_identifier() ~" --- TARGET: "~ target.database ) } #}
{# { log("###OVERRIDE schema.sql: default__create_schema     call common.rbac.prc_schema_in_"~ target.database ~ "('create schema "~ relation.without_identifier() ~ " with managed access');" ) } #}
  {%- call statement('create_schema') -%}
    call common.rbac.prc_schema_in_{{ target.database }}('create schema if not exists {{ relation.without_identifier() }} with managed access')
    {# create schema if not exists {{ relation.without_identifier() }} #}
    
  {% endcall %}
{% endmacro %}
