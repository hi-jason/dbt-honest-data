-- An honest change table: material rows name their dimensions, every
-- named dimension carries its payload, suppressed rows name nothing, and
-- every row locates its change inside an ordered window rather than at a
-- point.
select * from (
    values
        (cast('gh-1' as varchar), cast('material' as varchar),
         cast('pay' as varchar), cast(132000 as integer),
         cast(137000 as integer),
         cast(timestamp '2026-08-12 09:00:00' as timestamp),
         cast(timestamp '2026-08-13 09:00:00' as timestamp)),
        ('gh-2', 'material', 'title', null, null,
         timestamp '2026-08-12 09:00:00', timestamp '2026-08-13 09:00:00'),
        ('gh-3', 'markup_only', '', null, null,
         timestamp '2026-08-12 09:00:00', timestamp '2026-08-17 09:00:00')
) as t(job_key, change_class, changed_dimensions, pay_before, pay_after,
       changed_after, changed_before)
