{%- macro stg_erpall(table_name, erp_systems=[], include_columns=[],column_override=none,where=none,create_keys=True,column_prefix='',column_suffix='') %}

    {{- adapter.dispatch('stg_erpall', 'sie_dbt_utils')(table_name=table_name, erp_systems=erp_systems, include_columns=include_columns  , column_override=column_override,where=where,create_keys=create_keys,column_prefix=column_prefix,column_suffix=column_suffix) -}}

{%- endmacro %}

{% macro default__stg_erpall(table_name, erp_systems=[], include_columns=[],column_override=none,where=none,create_keys=True,column_prefix='',column_suffix='') -%}
{#-
----------------------------------------------------------------------------------------------------------------
Description:
    This macro will generate a select Statement that unions the table <table_name> from all the ERP Systems to which
        this project has access to.
----------------------------------------------------------------------------------------------------------------
Parameters: 
    * `table_name` (String): Name of the ERP table to generate the statement
    * `erp_systems` (array[String]) - optional: list of System names to include, if empty, then all the ERP systems will be used
    * `include_columns` (String) - optional: List of columns to include in your model. If empty then all the columns will be included
    * `column_override` (dict) - optional: A dictionary of explicit column type overrides, e.g. {"some_field": "varchar(100)"}.``
    * `where` (String) - optional: where clause to be included in each SELECT statement
    * `create_keys` (Boolean) - optional: if set to `False` then the Primary Keys and Hash Keys are not generated
----------------------------------------------------------------------------------------------------------------
Examples:
-- selecting some columns of bseg table from all the ERP systems.
with erpall as (
    {{ sie_dbt_utils.stg_erpall('bseg',
                  erp_systems=[],
                  include_columns=['PK_BSEG', 'SYSTEM', 'MANDT', 'BUKRS', 'BELNR', 'GJAHR', 'BUZEI', 'BUZID', 'AUGDT', 'AUGCP', 'AUGBL', 'BSCHL', 'KOART', 'LAST_UPDATED']) }}
)
select *
    from erpall

----------------------------------------------------------------------------------------------------------------
-#}

    {%- if execute -%}
    {%- set _table_name= table_name | upper | replace('"','') -%}
    {#- Get all the Schemas to which the user has access to.-#}
        {%- call statement('get_tables', fetch_result=True) %}
            show grants to role {{ target.database }}_DISTRIBUTE_O_R{{ '_RESTRICTED' if target.database.startswith('DEV_') else '' }}
        {%- endcall -%}

        {#- Identify the ERP Systems with full SELECT grant.-#}
        {%- set table_list = load_result('get_tables') -%}
            {% set erp_scope=[] -%}
            {%- for row in table_list['table'] -%}
                {%- if row.name.startswith('_PRD_DISTRIBUTE_ERP_RAW_') and row.name.endswith('_S_R_VIEWS') and row.privilege == 'USAGE' and row.granted_on == 'ROLE' -%}
                    {%- set erp = row.name | upper | replace('_PRD_DISTRIBUTE_ERP_RAW_', '') | replace('_S_R_VIEWS', '')  -%}
                    {%- if erp_systems is none or erp_systems == [] or erp in erp_systems | upper -%}
                        {%- do erp_scope.append('ERP_RAW_' ~ erp) -%}
                    {%- endif %}
                {%- endif -%}
            {%- endfor-%}

            {#- erp_scope contains all the ERP systems to which the project has access to -#}

        {%- if erp_scope and erp_scope != [] -%}
            {%- call statement('from_information_schema', fetch_result=True) %}
                select table_catalog as "table_catalog", table_schema as "table_schema", '"' || table_name || '"' as "table_name"
                    from prd_distribute.information_schema.tables
                        where table_catalog = 'PRD_DISTRIBUTE' and table_type = 'VIEW'
                        and table_schema in {{ sie_dbt_utils.array_to_in(erp_scope) }}
                        and table_name = '{{ _table_name | upper | replace('"', '') }}'
            {%- endcall -%}

            {%- set all_tables = load_result('from_information_schema') -%}
            
            {%- set tbl_relations = [] -%}
            {%- for tbl in all_tables['table'] -%}
                    {%- set tbl_relation = api.Relation.create(database=tbl.table_catalog, schema=tbl.table_schema, identifier=tbl.table_name, type='view') -%}
                    {%- if tbl_relation is not none -%}
                        {%- do tbl_relations.append(tbl_relation) -%}
                    {%- endif -%}
            {%- endfor -%}

        {%- else -%}
             {{ exceptions.raise_compiler_error("[Error 1] Your project does not have access to the ERP Systems requested: "~ erp_systems) }}
        {%- endif -%}

        {%- set all_columns = include_columns.copy() | map('upper') | list-%}
        {%- set available_cols = all_columns.copy() -%}
        {#-{%- do available_cols.append('SYSTEM') -%}-#}

        

/*
    This SQL code was generated using the sie_dbt_utils.stg_erpall() macro. on {{ modules.datetime.datetime.now() }}
    This is the staging view of SAP Table '{{ table_name }}' from the ERP Systems: {% for tbl in tbl_relations %}{{tbl.schema}}{% if not loop.last %}, {% endif %} {% endfor %}
    Requested columns: {{available_cols}}
*/                 
{% if tbl_relations is none or tbl_relations | length == 0 -%}
    {{ exceptions.raise_compiler_error("[Error 2] The table '" ~ table_name ~"' could not be found in PRD_DISTRIBUTE for the schemas you have access to. The identified schemas are: "~ erp_scope) }}
{%- endif -%}

select 
{% if create_keys -%}
-- Primary Keys
      {{ sie_dbt_utils.build_key_columns( table_name , column_type='PK', available_columns=available_cols, column_prefix=column_prefix, column_suffix = column_suffix) }}
-- Hash Keys
      {{ sie_dbt_utils.build_key_columns( table_name , column_type='HK', available_columns=available_cols, column_prefix=column_prefix, column_suffix = column_suffix) }}
-- Calculated Columns
{% endif %}
*
 from (

        {{-  sie_dbt_utils.union_relations_erp(tbl_relations, column_override=column_override, include=all_columns, system_column='system',where=where,column_prefix=column_prefix,column_suffix=column_suffix)  -}}
)
    {%- endif -%}
{%- endmacro -%}
