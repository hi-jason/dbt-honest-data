-- The month is fixed for repeatable tests; a real model should derive it from source dates.
-- Grain: (month_start, product_id). Decimal math is exact at 2dp.
select
    cast('2026-11-01' as date) as month_start,
    product_id,
    sum(gross_amount) as gross_amount,
    sum(discount_amount) as discount_amount,
    sum(net_amount) as net_amount
from {{ ref('fct_order_revenue') }}
group by product_id
