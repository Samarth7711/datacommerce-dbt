with customers as (
    select * from {{ ref('stg_jaffle_shop__customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

customer_metrics as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(order_id) as total_orders_count,
        sum(order_amount_usd) as lifetime_spend_usd
    from orders
    group by 1
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.full_name,
    m.first_order_date,
    m.most_recent_order_date,
    coalesce(m.total_orders_count, 0) as total_orders_count,
    coalesce(m.lifetime_spend_usd, 0) as lifetime_value_usd
from customers c
left join customer_metrics m
    on c.customer_id = m.customer_id
