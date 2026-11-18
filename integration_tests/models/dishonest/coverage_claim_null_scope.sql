-- A source-wide structural claim with NULL source cannot be evaluated.
select cast('listing-3' as varchar) as job_key,
       cast(null as varchar) as source,
       cast('no_parser_for_source' as varchar) as pay_absent_reason,
       cast(null as integer) as pay_min
