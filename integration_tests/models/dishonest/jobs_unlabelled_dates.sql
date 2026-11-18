-- The original defect, reproduced: a derived date with no label saying
-- it was derived. Indistinguishable from a measured one to anything
-- downstream. Row 2 is the mirror -- a label qualifying nothing.
select * from (
    values
        (cast('wd-1' as varchar), cast('workday' as varchar),
         cast(timestamp '2026-08-13 05:00:00' as timestamp),
         cast(null as varchar)),
        ('wd-2', 'workday', null, 'day_approximated')
) as t(job_key, source, posted_at, posted_at_precision)
