-- Full-refresh baseline before any update arrives.
select cast(1 as integer) as wrong_initial_count
where (select count(*) from {{ ref('inc_orders') }}) <> 2
union all
select cast(2 as integer)
where (select count(distinct order_id) from {{ ref('inc_orders') }}) <> 2
union all
select cast(3 as integer) from {{ ref('inc_orders') }}
where order_id not in (101,102)
   or (order_id=101 and net_amount <> cast('100.00' as numeric(12,2)))
   or (order_id=102 and net_amount <> cast('50.00' as numeric(12,2)))

