{% macro simple_cte(tuple_list) -%}
{#-
----------------------------------------------------------------------------------------------------------------
Description:
    This macro will generate a sequence of CTEs based on the models it is referring to.
----------------------------------------------------------------------------------------------------------------
Parameters: 
    * `tuple_list` (list of tuples): list of pairs: `cte name` and `model name`
----------------------------------------------------------------------------------------------------------------
Examples:
{{ sie_dbt_utils.simple_cte(
        [
            ("ekko", "stg_ekko"),
            ("ekpo", "stg_ekpo"),
            ("bseg", "stg_bseg")
        ])
}}

--> Will generate the code:
WITH ekko AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_ekko

), ekpo AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_ekpo

), bseg AS (

    SELECT * 
    FROM DEV_DCC_P.dbt_Z003HMBT_STAGING.stg_bseg

)
----------------------------------------------------------------------------------------------------------------
-#}

    {{- return(adapter.dispatch('simple_cte', 'sie_dbt_utils')(tuple_list=tuple_list)) -}}
{%- endmacro %}

{% macro default__simple_cte(tuple_list) -%}

WITH{% for cte_ref in tuple_list %} {{cte_ref[0]}} AS (

    SELECT * 
    FROM {{ ref(cte_ref[1]) }}

)
    {%- if not loop.last -%}
    ,
    {%- endif -%}
    
    {%- endfor -%}

{%- endmacro %}
