{%- macro union_relations_erp(relations, column_override=none, include=[], exclude=[], source_column_name=none, system_column=none,where=none,column_prefix='',column_suffix='') -%}
    {{- adapter.dispatch('union_relations_erp', 'sie_dbt_utils')(relations=relations, column_override=column_override, include=include  , exclude=exclude, source_column_name=source_column_name,system_column=system_column,where=where,column_prefix=column_prefix,column_suffix=column_suffix) -}}

{%- endmacro %}

{% macro default__union_relations_erp(relations, column_override=none, include=[], exclude=[], source_column_name=none, system_column=none,where=none,column_prefix='',column_suffix='') %}
{#-
{#-
----------------------------------------------------------------------------------------------------------------
Description:
    This macro is based on the `dbt_utils.union_relations` macro. It will generate a cleaner code and is mainly targeted for the ERP tables.
    Column System will be created if required
----------------------------------------------------------------------------------------------------------------
Parameters: 
    - table_name(String): Name of the ERP table to generate the statement
    - erp_systems(array[String]) - optional: list of System names to include, if empty, then all the ERP systems will be used
    - include_columns(String) - optional: List of columns to include in your model. If empty then all the columns will be included
    - column_override(dict) - optional: A dictionary of explicit column type overrides, e.g. {"some_field": "varchar(100)"}.``
    - where(String) - optional: where clause to be included in each SELECT statement
    - column_prefix - optional: adds a prefix to the column name
    - column_suffix - optional: adds a suffix to the column name
----------------------------------------------------------------------------------------------------------------
Examples:


----------------------------------------------------------------------------------------------------------------
-#}
    {%- if exclude and include -%}
        {{ exceptions.raise_compiler_error("Both an exclude and include list were provided to the `union` macro. Only one is allowed") }}
    {%- endif -%}

    {#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. -#}
    {%- if not execute %}
        {{ return('') }}
    {% endif -%}

    {%- set column_override = column_override if column_override is not none else {} -%}

    {%- set relation_columns = {} -%}
    {%- set column_superset = {} -%}
    
    {%- set force_cast_columns = [] -%}

    {%- for relation in relations -%}

        {%- do relation_columns.update({relation: []}) -%}

        {%- do dbt_utils._is_relation(relation, 'union_relations') -%}
        {%- do dbt_utils._is_ephemeral(relation, 'union_relations') -%}
        {%- set cols = adapter.get_columns_in_relation(relation) -%}
        {%- for col in cols -%}

        {#- If an exclude list was provided and the column is in the list, do nothing -#}
        {%- if exclude and col.column in exclude -%}

        {#- If an include list was provided and the column is not in the list, do nothing -#}
        {%- elif include and col.column not in include -%}

        {#- Otherwise add the column to the column superset -#}
        {%- else -%}

            {#- update the list of columns in this relation -#}
            {%- do relation_columns[relation].append(col.column) -%}

            {%- if col.column in column_superset -%}

                {%- set stored = column_superset[col.column] -%}
                {%- if col.is_string() and stored.is_string() and col.string_size() > stored.string_size() -%}

                    {%- do column_superset.update({col.column: col}) -%}

                {%- endif %}
                {%- if col.dtype != stored.dtype -%}
                    {{ log(col.column ~': stored_type: ' ~ stored.data_type ~ ' current: ' ~col.data_type ~' .....' ~ col.dtype, info=True) }}
                    {%- do force_cast_columns.append(col.column) -%}

                    {%- do column_superset.update({col.column: stored}) -%}

                {%- endif %}

            {%- else -%}

                {%- do column_superset.update({col.column: col}) -%}

            {%- endif -%}

        {%- endif -%}

        {%- endfor -%}
    {%- endfor -%}

    {%- set ordered_column_names = column_superset.keys() -%}

    {% if (include | length > 0 or exclude | length > 0) and not column_superset.keys() %}
        {%- set relations_string -%}
            {%- for relation in relations -%}
                {{ relation.name }}
            {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        {%- endset -%}

        {%- set error_message -%}
            There were no columns found to union for relations {{ relations_string }}
        {%- endset -%}

        {{ exceptions.raise_compiler_error(error_message) }}
    {%- endif -%}

    {%- for relation in relations %}
        {%- set first_relation = loop.first %}
 (   -- {{ relation.schema }}.{{ relation.name }}
    select
{%- set prefix = column_prefix ~ '_' if column_prefix != '' else '' -%}
{%- set suffix = '_' ~ column_suffix if column_suffix != '' else '' -%}
{% if system_column %}    {{""}}      cast('{{ relation.schema[-5:] }}' as varchar(5)) as {{ adapter.quote(prefix ~ system_column ~ suffix)|trim|upper }},{% endif %}
{% for col_name in ordered_column_names -%}
    {%- set col = column_superset[col_name] %}
    {%- set col_type = column_override.get(col.column, col.data_type) %}
    {%- set force_cast = col.column in force_cast_columns %}
    {%- set col_name = adapter.quote(col_name) if col_name in relation_columns[relation] else 'null' -%}
    {%- if first_relation or force_cast -%}
{{""}}      cast({{ col_name }} as {{ col_type | replace('character varying', 'varchar')}}) {{ adapter.quote(prefix ~ col.column ~ suffix)|trim|upper }}
    {%- else -%}
{{""}}      {{ col_name }}{% if col_name == 'null' %} {{ adapter.quote(prefix ~ col.column ~ suffix)|trim|upper }}{% endif %}
    {%- endif %}{% if not loop.last %},
{% endif -%}                    
{%- endfor %}

    from {{ relation }}
     {% if where -%}
        where {{ where }}
     {%- endif %}
 )

        {%- if not loop.last %}
union all
        {% endif -%}

    {%- endfor -%}

{%- endmacro -%}
