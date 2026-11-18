-- Native unique/not_null both pass on an empty relation. Guard it separately.
select cast(1 as integer) as missing_population
where not exists (select 1 from {{ ref('dim_products') }})
