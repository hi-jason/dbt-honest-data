select order_id from {{ ref('inc_orders') }}
group by order_id having count(*) > 1
