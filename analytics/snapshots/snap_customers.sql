{% snapshot snap_customers %}

{{
    config(
      target_database='DATACOMMERCE_ANALYTICS',
      target_schema='DBT_DEV_SNAPSHOTS',
      unique_key='id',
      strategy='check',
      check_cols=['first_name', 'last_name'],
      invalidate_hard_deletes=True
    )
}}

select
    id,
    first_name,
    last_name,
    _loaded_at
from {{ source('jaffle_shop', 'customers') }}

{% endsnapshot %}
