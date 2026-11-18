-- A populated date with an empty label must not look exactly measured.
select cast('listing-1' as varchar) as job_key,
       cast('2026-10-01' as date) as posted_at,
       cast('   ' as varchar) as posted_at_precision
