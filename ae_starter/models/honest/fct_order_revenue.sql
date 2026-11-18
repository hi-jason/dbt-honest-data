-- Grain: order_id. An order whose product is missing from dim_products is
-- kept with a null product_status; the relationships test warns about it.
-- An absent discount is defined to mean zero (explicit business policy).
select
    o.order_id,
    o.product_id,
    p.status as product_status,
    o.gross_amount,
    coalesce(o.discount_amount, cast(0 as numeric(12,2))) as discount_amount,
    o.gross_amount - coalesce(o.discount_amount, cast(0 as numeric(12,2))) as net_amount
from {{ ref('stg_orders') }} as o
left join {{ ref('dim_products') }} as p on o.product_id = p.product_id
