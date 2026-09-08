{{
    config(
        materialized='table'
    )
}}

with days as (
    -- Generate dates spanning from 2020-01-01 through 2030-12-31
    select
        dateadd('day', seq4(), '2020-01-01'::date) as date_day
    from table(generator(rowcount => 4018))
)

select
    cast(date_day as date) as date_day
from days
