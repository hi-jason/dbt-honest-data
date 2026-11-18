-- The failure this catches is a real sequence, not a hypothetical: the
-- parser landed, most rows moved to a real number, and these did not.
-- They still claim nobody could read this source while the row beside
-- them proves otherwise.
select * from (
    values
        (cast('gh-1' as varchar), cast('greenhouse' as varchar),
         cast(null as integer), cast('no_parser_for_source' as varchar)),
        ('gh-2', 'greenhouse', 180000, null)
) as t(job_key, source, pay_min, pay_absent_reason)
