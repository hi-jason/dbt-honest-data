-- After phase 2 and identical replay: corrected 101 + unchanged 102 + new 103.
select cast(1 as integer) as bad_final_count
where (select count(*) from {{ ref('inc_orders') }}) <> 3
union all select cast(2 as integer)
where (select count(distinct order_id) from {{ ref('inc_orders') }}) <> 3
union all
select cast(3 as integer)
from {{ ref('inc_orders') }}
where order_id not in (101,102,103)
   or (order_id=101 and
        (net_amount <> cast('120.00' as numeric(12,2))
         or event_at <> cast('2026-10-28' as timestamp)
         or updated_at <> cast('2026-11-05' as timestamp)))
   or (order_id=102 and net_amount <> cast('50.00' as numeric(12,2)))
   or (order_id=103 and net_amount <> cast('20.00' as numeric(12,2)))

