{% macro alphanum(value_field, target_length) -%}
{#
----------------------------------------------------------------------------------------------------------------
Description:
    The macro will fill numeric content with leading zeros up to target_length.
    Alpha numeric content will be unchanged.
    Original Documentation from SAP:
    https://help.sap.com/products/SAP_HANA_PLATFORM/4fe29514fd584807ac9f2a04f6754767/e4887a42a3eb4d5d88bf84da66c07668.html?version=2.0.02
----------------------------------------------------------------------------------------------------------------
Parameters: 
    value_field:     content for the alpha conversion
    target_length:   final lenght of the field. 
----------------------------------------------------------------------------------------------------------------
-#}
        (case when REGEXP_LIKE ({{value_field}},$$^\s*\d+$$) then lpad(ltrim({{value_field}}),{{target_length}},'0') 
            else {{value_field}} 
        end)

{%- endmacro %}
