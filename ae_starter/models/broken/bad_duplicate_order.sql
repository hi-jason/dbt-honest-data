-- Two rows share one order identity.
select cast(501 as integer) as order_id
union all select cast(501 as integer)
