{% macro neat_log(message, result=None, info=True) -%}
{#
This macro will produce log messages similar to the ones on the mail dbt Cloud job logs.
 Parameters:
    - message (string): Message to present (up to 80 characters)
    - result (string):  status message to show at the end (for example: the run time)
    - info (boolean): if True, the message will show on the main log

Examples:

{{neat_log('First Message')}}
{{neat_log('First Message', 'Success!')}}
{{neat_log('First Message with a longer text', 'Success!')}}
..
/*
First Message ..................................................................
First Message .................................................................. [Success!]
First Message with a longer text ............................................... [Success!]
*/

#}
    {%- set logText = message ~ ' '
                    ~ ('.' * (80 - 1 - message | length ))
                    ~ ( (' ['~ result ~ ']' ) if result != None)
    -%}
    {{- log(logText, info=True) -}}    
{%- endmacro %}
