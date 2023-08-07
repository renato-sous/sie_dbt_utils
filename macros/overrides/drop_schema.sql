{% macro default__drop_schema(relation) -%}
{# { log("###OVERRIDE schema.sql: default__drop_schema ") } #}
  {%- call statement('drop_schema') -%}
    call common.rbac.prc_schema_in_{{ target.database }}('drop schema if not exists {{ relation.without_identifier() }} cascade')
    {# drop schema if exists {{ relation.without_identifier() }} cascade #}
  {% endcall %}
{% endmacro %}
