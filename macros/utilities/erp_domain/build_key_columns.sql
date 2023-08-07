
{%- macro build_key_columns(in_table_name, key_columns=[], column_type='%', available_columns=none, column_prefix='', column_suffix='') -%}
{#-
----------------------------------------------------------------------------------------------------------------
Description:
    This macro will generate the key columns, by querying the seed <seed_source>. The key columns
    are generated using the surrogate_key macro.
----------------------------------------------------------------------------------------------------------------
Parameters: 
    - in_table_name(String): Name of the source table to be used. Ex: KNA1
    - key_columns(array[String]): list of columns to be retrieved. [] to retrieve all the columns
    - column_type(String): type of column to take from the seed table. typically 'PK' or 'HK' or '%' for both
    - available_columns(array[String]): in case your model only has certain columns lists. include here to filter the HK/PK that match
----------------------------------------------------------------------------------------------------------------
Examples:
-- all PK and HK
{{ build_key_columns( 'vbak') }}

-- PK only:
{{ build_key_columns( 'vbak', column_type = 'PK') }}

-- specific HK only:
{{ build_key_columns( 'vbak', key_columns=['hk_aufnr','hk_kokrs'], column_type='HK') }}
----------------------------------------------------------------------------------------------------------------
-#}
{% set in_table_name = in_table_name|replace('"','')%}
  {%- set sql_statement %}
      select column_name, regexp_replace(columns, $$[\[\]\s]$$, '') as columns, split(columns, ',') as COL_ARRAY
      from PRD_DISTRIBUTE.DOM_ERP.CUST_ALL_DOM_TABLE_KEYS where upper(table_name) = upper('{{ in_table_name }}') and type like '{{ column_type }}'
      {% if key_columns is iterable and key_columns != [] %}and column_name in (
        {% for kcol in key_columns %}'{{kcol}}' {% if not loop.last %}, {% endif %}{% endfor %}
      ){% endif -%}
  {%- endset -%}

  {% if execute %}   
    {%- set hd_columns = dbt_utils.get_query_results_as_dict(sql_statement) -%}
    
    {{- log("number of entries: " ~ (hd_columns['COLUMNS'] | count)) -}}
    {%- if column_type == 'PK' and (hd_columns['COLUMNS'] | count) == 0 -%}
        {%- set error_message =
           'Warning: No Primary Keys were defined for table "{}" on seed file "{}"'.format(in_table_name, seed_source) -%}
        {%- do exceptions.warn(error_message) -%}
        /* {{ error_message }} */
    {%- endif -%}
  
    {%- for col in hd_columns['COLUMNS'] -%}
      {%- if loop.first -%} -- {{ column_type }} Columns defined in DOM_ERP {% endif %}
      
        -- {{ hd_columns['COLUMN_NAME'][loop.index-1] }}
      {%- set cols = hd_columns['COLUMNS'][loop.index-1].replace("'", '').replace('"', "'").split(',') -%}

      {#- Work the string and make it a proper array #}
      {%- set colsp = hd_columns['COLUMNS'][loop.index-1].split(',') -%}
      {%- set new_columns = [] -%}
      {%- set all_null = [] -%}
          {%- for coli in colsp -%}
              {%- set new_col = (coli | trim("'")) -%}
              {%- if ("'" in new_col)  %}
                {%- set new_col = new_col|replace('"','') %}
              {%- endif -%}

            {#- Check if the SQL statement has all the columns required by the PK or HK -#}
            {#- column 'SYSTEM' was ignored, as this is the default for stg_erpall and will not be included on available_columns -#}
            {%- if available_columns is not none and available_columns is iterable and available_columns != [] and ( new_col | upper ) not in available_columns and new_col != 'SYSTEM' -%}
            {{-""-}}
            {{ available_columns }}
            {%- else %}
              {%- set prefix = column_prefix ~ '_' if column_prefix != '' else '' -%}
              {%- set suffix = '_' ~ column_suffix if column_suffix != '' else '' -%}
              {%- set new_col = (prefix ~ new_col ~ suffix)|trim|upper -%}
              {%- set new_columns = new_columns.append(new_col) %}
              {%- if not loop.last %}{% do all_null.append('-') -%}{%- endif -%}
            {%- endif -%}
          {%- endfor%}
      {%- if new_columns | length == colsp | length %}
      coalesce(
          {%- set sgkey='' -%}
          {%- if dbt_utils.generate_surrogate_key -%}
          {#- If the project is already using dbt Core 1.3 and dbt_utils 1.0 -#}
          {%- set sgkey = dbt_utils.generate_surrogate_key( new_columns ) -%}
          {%- else -%}
          {#- If the project is not yet using dbt Core 1.3 or dbt_utils 1.0 -#}
          {%- set sgkey = dbt_utils.surrogate_key( new_columns ) -%}
          {%- endif -%}
            {{- sgkey | replace('md5(cast(', 'md5_binary(cast(') | replace('md5_binary(', 'md5_binary(nullif(') | replace('as \n    varchar\n)', 'as varchar )') | replace('))', "), '" ~ (all_null | join("")) ~ "') ") }} ), '00000000000000000000000000000000'::binary(16))
        as {{ hd_columns['COLUMN_NAME'][loop.index-1] }}, {#{% if not loop.last %},{% endif %}#}
      {%- else -%}
        {{""}}-- not included. It requires the Columns: {{ colsp }}
      {%- endif -%}
    {%- endfor -%}
  {% endif %}
{%- endmacro %}
