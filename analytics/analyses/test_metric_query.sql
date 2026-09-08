-- Compile dynamic SQL for revenue and order count aggregated by order_status
select
    order_status,
    sum(order_amount_usd) as gross_revenue,
    count(distinct order_id) as total_orders,
    round(sum(order_amount_usd) / nullif(count(distinct order_id), 0), 2) as average_order_value
from {{ ref('fct_orders') }}
group by 1
order by gross_revenue desc
