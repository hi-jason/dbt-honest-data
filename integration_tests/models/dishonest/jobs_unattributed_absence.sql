-- A bare null where pay should be, conflating "the employer declined to
-- publish" with "we cannot read this source". Row 2 is the incoherent
-- mirror: a reason for an absence that did not happen.
select * from (
    values
        (cast('gh-1' as varchar), cast('greenhouse' as varchar),
         cast(null as integer), cast(null as varchar)),
        ('gh-2', 'greenhouse', 180000, 'not_disclosed')
) as t(job_key, source, pay_min, pay_absent_reason)
