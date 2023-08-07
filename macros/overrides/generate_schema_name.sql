{% macro default__generate_schema_name(custom_schema_name, node) -%}
    
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- elif (target.user.endswith('_TU_ETL_DBT')) and not custom_schema_name is none -%}
    {#- For Technical users, use the Custom Schemas only, and when available -#}
        {{ ( ( target.schema ~'_') if target.name == 'CI') ~ custom_schema_name | trim  }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
