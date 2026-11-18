-- Synthetic reference set. Grain: product_id.
select cast(1 as integer) as product_id, cast('active' as varchar) as status
union all
select cast(2 as integer), cast('inactive' as varchar)
