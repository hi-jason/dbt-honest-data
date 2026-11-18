-- The field is present in only one of four rows, below the declared
-- coverage band. Valid-looking SQL does not catch that change alone.
select * from (
    values
        (cast('gh-1' as varchar),
         cast(timestamp '2026-08-12 09:00:00' as timestamp)),
        ('gh-2', null),
        ('gh-3', null),
        ('gh-4', null)
) as t(job_key, posted_at)
