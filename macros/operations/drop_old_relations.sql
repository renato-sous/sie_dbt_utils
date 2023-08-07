{% macro drop_old_relations(schema=None,dry_run='true') %}
    {{- return(adapter.dispatch('drop_old_relations', 'sie_dbt_utils')(schema=schema,dry_run=dry_run)) -}}
{%- endmacro -%}

{% macro snowflake__drop_old_relations(schema=None,dry_run='true') %}
{#- -------------------------------------------------------------------------------------------------------------
Description:

    This macro can be used to drop objects from the database, that are not in the dbt project anymore.
    dbt run-operation drop_old_relations --args "{dry_run: 'true', schema: '(''TRANFORM'')'}"

---------------------------------------------------------------------------------------------------------------- 
Parameters: 

    dry_run:      The recommended default dry_run will log the drop-statements to be copied and ran manually.
                  dry_run='false' would directly run the drop-statements.
                  - dry_run='true' is only possible while in a dbt Cloud job

    schema:       Optional parameter to define a list of schemas as sql list in uppercase.
                  Needs to be used for technical users like dbt cloud jobs, because there the target.schema is "dbt".
                  can be:
                    - string. example: 'STAGING'
                    - array:  example: ['STAGING','TRANSFORM']
---------------------------------------------------------------------------------------------------------------- -#}
{% if execute %}
  {% set current_models=[] %}
  {% for node in graph.nodes.values()
     | selectattr("resource_type", "in", ["model", "seed", "snapshot"])%}
    {% do current_models.append(node.name) %}
							  
  {% endfor %}
{% endif %}
{% set cleanup_query %}
      with models_to_drop as (
        select
          case 
            when table_type = 'BASE TABLE' then 'TABLE'
            when table_type = 'VIEW' then 'VIEW'
          end as relation_type,
          concat_ws('.', table_catalog, table_schema, table_name) as relation_name,
          table_owner
        from 
          {{ target.database }}.information_schema.tables
        {% if schema %} where table_schema in ('{{ "', '".join(schema) if schema is iterable and schema is not string else schema}}')
        {% else %} where table_schema ilike '{{ target.schema }}%'
        {%- endif %}
          and table_name not in
            ({%- for model in current_models -%}
                '{{ model.upper() }}'
                {%- if not loop.last -%}
                    ,
                {%- endif -%}
            {%- endfor -%}))
      select 
        'drop ' || relation_type || ' ' || relation_name || '; /* owner: ' || table_owner ||'*/' as drop_commands
      from 
        models_to_drop
      
      -- intentionally exclude unhandled table_types, including 'external table`
      where drop_commands is not null
      order by relation_name
  {% endset %}
{#% do log(cleanup_query, info=False) %#}
{% set drop_commands = run_query(cleanup_query).columns[0].values() %}
{% if drop_commands %}
  {% if dry_run == 'false' %}
    {% if target.name == 'default' %}
      {% do log('dry_run cannot be set to "true" while in development. Please copy the statements below and run in Snowflake.', True) %}
    {% else %}
      {% do log('The objects will be dropped from the database.', True) %}
    {% endif %}
  {% else %}
      {% do log('Running in dry_mode. Please copy the statements below and run in Snowflake.', True) %}
  {% endif %}
  {% set ns = namespace(drop_statements='-- List of Drop Statements:') %}
  {% for drop_command in drop_commands %}
			
			
    {% if dry_run == 'false' and target.name != 'default'%}
      {% do log(drop_command, True) %}
      {% do run_query(drop_command) %}
    {% else %}
      {% set ns.drop_statements = ns.drop_statements ~ '\r\n' ~ drop_command  %}
    {% endif %}
  {% endfor %}
  
  {% do log(ns.drop_statements, True) %}
{% else %}
  {% do log('No relations to clean.', True) %}
{% endif %}
{%- endmacro -%}
