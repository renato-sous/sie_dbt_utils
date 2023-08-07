{% macro cast_masked_columns(column_name=none, length=32) %}
{#
This macro intents to solve an issue that happens in dbt when materializing columns that have Masking Policies, while in Development Environment.
The error happens when the column is a varchar( <32 ), and the masking policy will deliver an hashed value with 32 characters. It will not be able to insert the record in the new dbt Table and fails.
The macro will do the cast to a desired length ONLY when the role being used is *_RESTRICTED.

 Parameters:
    - column_name (string): column_name that will be cast as VARCHAR(<length>)
    - length (integer): new length to apply to this column

Examples (using *_DEVELOPER role):
    {{ cast_masked_columns('usnam')}}
    --> cast( usnam as varchar(32) ) as usnam
    {{ cast_masked_columns('usr02.usnam', 64)}}
    --> cast( usr02.usnam as varchar(64) ) as usnam
    {{ cast_masked_columns('usnam', 2)}}
    --> cast( usnam as varchar(2) ) as usnam

Examples ( in QUA or PRD environments ):
    {{ cast_masked_columns('usnam')}}
    --> usnam
    {{ cast_masked_columns('usnam', 64)}}
    --> usnam
    {{ cast_masked_columns('usnam', 2)}}
    --> usnam
#}

    {% if column_name is not string or length is not number %}
        {{ exceptions.raise_compiler_error("Invalid wrong arguments passed. Expected (string, length)  received ('" ~ column_name ~"', '"~ length ~"')") }}
    {% endif %}

    {% if target.role[-11:] == '_RESTRICTED' %}
        {{ return('cast( ' ~ column_name ~' as varchar(' ~length ~') ) as ' ~ (column_name if not '.' in column_name else column_name.split('.')[1] ) ) }}
    {% else %}
        {{ return(column_name ~' /*'~target.name ~'*/') }}
    {% endif %}
{% endmacro %}
