-- Deliberately WRONG at key grain: +10 to 101, -10 to 102.
-- Aggregate total remains 130.00 and fools a total-only check.
select order_id,
       net_amount + case when order_id=101 then cast(10 as numeric(12,2))
                         when order_id=102 then cast(-10 as numeric(12,2))
                         else cast(0 as numeric(12,2)) end as net_amount
from {{ ref('ledger_source') }}
