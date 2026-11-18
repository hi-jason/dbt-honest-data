-- Two invalid intervals: one lacks a bound and the other runs backwards.
-- Neither can support a valid "changed between X and Y" claim.
select * from (
    values
        (cast('gh-1' as varchar),
         cast(timestamp '2026-08-13 09:00:00' as timestamp),
         cast(null as timestamp)),
        ('gh-2', timestamp '2026-08-17 09:00:00', timestamp '2026-08-12 09:00:00')
) as t(job_key, changed_after, changed_before)
