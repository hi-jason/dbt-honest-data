-- Synthetic source. Grain: order_id. The real project would use source().
select cast(101 as integer) as order_id, cast(1 as integer) as product_id,
       cast(100.00 as numeric(12,2)) as gross_amount,
       cast(10.00 as numeric(12,2)) as discount_amount
union all
select cast(102 as integer), cast(2 as integer),
       cast(50.00 as numeric(12,2)), cast(0.00 as numeric(12,2))
