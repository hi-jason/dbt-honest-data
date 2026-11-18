-- Independent synthetic fact ledger: grain order_id. Net total = 130.00.
select cast(101 as integer) order_id, cast('100.00' as numeric(12,2)) net_amount
union all select 102, cast('50.00' as numeric(12,2))
union all select 103, cast('-20.00' as numeric(12,2))
