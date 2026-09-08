{% macro pivot_payments(payment_methods) -%}
    {% for method in payment_methods %}
        coalesce(sum(case when payment_method = '{{ method }}' then amount_usd end), 0) as {{ method }}_amount_usd{% if not loop.last %},{% endif %}
    {% endfor %}
{%- endmacro %}
