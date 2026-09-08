with source as (
    select * from {{ source('stripe', 'payments') }}
),

transformed as (
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status as payment_status,
        -- Convert cents to dollars
        round(amount / 100.0, 2) as amount_usd,
        created as payment_date
    from source
)

select * from transformed