{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        cluster_by=['order_date']
    )
}}

{% set payment_methods = ['credit_card', 'coupon', 'bank_transfer'] %}

with orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
    {% if is_incremental() %}
      where order_date >= (select coalesce(dateadd('day', -3, max(order_date)), '1970-01-01') from {{ this }})
    {% endif %}
),

payments as (
    select * from {{ ref('stg_stripe__payments') }}
    where payment_status = 'success'
),

order_payments as (
    select
        order_id,
        sum(amount_usd) as total_amount_usd,
        {{ pivot_payments(payment_methods) }}
    from payments
    group by 1
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    coalesce(p.total_amount_usd, 0) as order_amount_usd,
    {% for method in payment_methods %}
        coalesce(p.{{ method }}_amount_usd, 0) as {{ method }}_amount_usd,
    {% endfor %}
    current_timestamp() as dbt_updated_at
from orders o
left join order_payments p
    on o.order_id = p.order_id
