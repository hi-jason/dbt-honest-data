select order_id from {{ ref('bad_inc_append') }}
group by order_id having count(*) > 1
