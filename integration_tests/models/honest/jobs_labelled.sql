-- An honest jobs table: every inferred value carries its label, every
-- absent value carries its reason, and the one coverage claim it makes
-- ("we cannot read pay from workday") is not contradicted by any workday
-- row that does carry pay.
select * from (
    values
        (cast('gh-1' as varchar), cast('greenhouse' as varchar),
         cast(timestamp '2026-08-12 09:00:00' as timestamp),
         cast('exact' as varchar), cast(180000 as integer),
         cast(null as varchar)),
        ('gh-2', 'greenhouse', timestamp '2026-08-13 09:00:00',
         'exact', null, 'not_disclosed'),
        ('wd-1', 'workday', timestamp '2026-08-13 05:00:00',
         'day_approximated', null, 'no_parser_for_source'),
        ('wd-2', 'workday', null, null, null, 'no_parser_for_source')
) as t(job_key, source, posted_at, posted_at_precision, pay_min, pay_absent_reason)
