-- This NULL scope does NOT carry the coverage claim being tested.
select cast('listing-4' as varchar) as job_key,
       cast(null as varchar) as source,
       cast('not_disclosed' as varchar) as pay_absent_reason,
       cast(null as integer) as pay_min
