-- A model with one row per original order after grouping.
select order_id, sum(net_amount) as net_amount
from {{ ref('ledger_source') }}
group by order_id
