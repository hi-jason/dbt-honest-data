-- Row 1 is called material but names no changed field, so the UI may
-- show an empty change panel. Row 2 has a changed value without the
-- matching claim; consumers filtering on the claim may omit it.
select * from (
    values
        (cast('gh-1' as varchar), cast('material' as varchar),
         cast('' as varchar), cast(null as integer), cast(null as integer)),
        ('gh-2', 'markup_only', '', 132000, 137000)
) as t(job_key, change_class, changed_dimensions, pay_before, pay_after)
