-- Equal bounds fail when allow_equal is the string 'false'.
select cast('m1' as varchar) as record_id,
       cast('2026-10-01' as date) as lower_bound,
       cast('2026-10-01' as date) as upper_bound
