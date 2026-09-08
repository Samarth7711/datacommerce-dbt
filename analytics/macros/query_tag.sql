{% macro set_query_tag() -%}
  {% set current_model = model.name if model is defined else 'generic_dbt_run' %}
  {% set new_query_tag = '{"dbt_model": "' ~ current_model ~ '", "environment": "dev"}' %}
  alter session set query_tag = '{{ new_query_tag }}';
{%- endmacro %}
