-- A synthetic export with a deliberately restricted column list.
-- A passing column-name test alone does not establish publication safety.
select * from (
    values
        (cast('gh-1' as varchar), cast('Example Co' as varchar),
         cast('Data Engineer' as varchar), cast(180000 as integer))
) as t(job_key, company, title, pay_min)
