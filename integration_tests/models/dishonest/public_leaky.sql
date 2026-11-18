-- Allowlist erosion, in its realistic form: somebody added a column
-- because it was convenient and it was right there.
select * from (
    values
        (cast('gh-1' as varchar), cast('Example Co' as varchar),
         cast('synthetic reviewer note' as varchar), cast(0.91 as double precision))
) as t(job_key, company, internal_note, internal_score)
