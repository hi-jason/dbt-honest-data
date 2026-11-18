{{ config(materialized='incremental', incremental_strategy='append') }}
-- Deliberately WRONG: appending a corrected ID creates a duplicate.
select order_id, net_amount, event_at, updated_at
from {{ ref('source_events') }}
{% if is_incremental() %}
where updated_at > (
    select coalesce(max(updated_at), cast('1900-01-01' as timestamp))
    from {{ this }}
)
{% endif %}
