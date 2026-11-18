{{ config(materialized='incremental', unique_key='order_id', incremental_strategy='delete+insert') }}
-- A deliberately simple SCD1 upsert, NOT historical SCD2.
-- Watermark on updated_at (when the source changed the row), not event_at.
-- Two production habits shown here:
--   1. A lookback window: re-read the last few days on every run, so an
--      update that lands late (timestamp at or just below the watermark)
--      is not skipped. delete+insert makes re-reading a row harmless.
--   2. Dedupe inside the batch: if one order changed twice since the last
--      run, keep only its latest version. Without this, delete+insert
--      would insert both versions and duplicate the order.
{% set lookback_days = var('lookback_days', 3) | int %}
with changed as (
    select order_id, net_amount, event_at, updated_at
    from {{ ref('source_events') }}
    {% if is_incremental() %}
    where updated_at >= (
        select {{ dbt.dateadd('day', -lookback_days,
                              "coalesce(max(updated_at), cast('1900-01-01' as timestamp))") }}
        from {{ this }}
    )
    {% endif %}
),
ranked as (
    select
        changed.*,
        row_number() over (partition by order_id order by updated_at desc) as version_rank
    from changed
)
select order_id, net_amount, event_at, updated_at
from ranked
where version_rank = 1
