-- Synthetic event stream with two source snapshots.
-- Batch 2 corrects 101 with an older *event time* but a later *update time*,
-- and carries two versions of the new order 103 (it changed twice between
-- runs). The upsert must keep only 103's latest version.
{% set batch = var('batch', 1) | int %}
select cast(101 as integer) as order_id,
       cast({{ "'120.00'" if batch == 2 else "'100.00'" }} as numeric(12,2)) as net_amount,
       cast('{{ "2026-10-28" if batch == 2 else "2026-11-01" }}' as timestamp) as event_at,
       cast('{{ "2026-11-05" if batch == 2 else "2026-11-01" }}' as timestamp) as updated_at
union all
select cast(102 as integer), cast('50.00' as numeric(12,2)),
       cast('2026-11-01' as timestamp), cast('2026-11-02' as timestamp)
{% if batch == 2 %}
union all
select cast(103 as integer), cast('15.00' as numeric(12,2)),
       cast('2026-11-03' as timestamp), cast('2026-11-03' as timestamp)
union all
select cast(103 as integer), cast('20.00' as numeric(12,2)),
       cast('2026-11-03' as timestamp), cast('2026-11-04' as timestamp)
{% endif %}
