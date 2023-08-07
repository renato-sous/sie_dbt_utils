{% macro default__generate_alias_name(custom_alias_name=none, node=none) -%}
   {%- set use_long_name =  var("siemens_long_names_in_models", false) and node.config.get('siemens_use_long_name', default=true) -%}
   {%  set path_separator=  var("siemens_long_names_in_models_folder_delimiter", '_') -%}
   {%  set path_break    =  var("siemens_long_names_in_models_object_delimiter", '$') -%}

   {%- if use_long_name and custom_alias_name is none -%}
       {# If variable is defined, then build the new alias name with the path #}
        {# {% set new_alias_name = (node.path|replace("/" ~ node.name ~ ".sql","")|replace("/",".") ~ "/" ~ node.name)|upper()  -%} #}
        {# {% set new_alias_name = (node.path|replace("/" ~ node.name ~ ".sql","")|replace("/","_") ~ "$" ~ node.name)|upper()  -%} #}
        {%- set new_alias_name = (node.path|replace("/" ~ node.name ~ ".sql","")|replace("/", path_separator ) ~ path_break ~ node.name)|upper()  -%}
       {# {{ '"' ~new_alias_name ~ '"'}} #}
       {{ new_alias_name }}
       
    {%- else -%}
        {%- if custom_alias_name is none -%}

            {{ node.name }}

        {%- else -%}

            {{ custom_alias_name | trim }}

        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
