-- Two distinct records occupy the same business grain.
select cast('2026-11-01' as date) as month_start,
       cast(1 as integer) as product_id, cast(1 as integer) as source_id
union all
select cast('2026-11-01' as date), cast(1 as integer), cast(2 as integer)
