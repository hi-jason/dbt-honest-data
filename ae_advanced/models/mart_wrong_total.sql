-- Deliberately WRONG total: +10 to 101, no compensating reduction.
select order_id,
       net_amount + case when order_id=101 then cast(10 as numeric(12,2))
                         else cast(0 as numeric(12,2)) end as net_amount
from {{ ref('ledger_source') }}
