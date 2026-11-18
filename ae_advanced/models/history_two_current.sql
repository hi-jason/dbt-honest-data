-- Deliberately WRONG: two simultaneously current versions.
select cast(1 as integer) account_id, cast(11 as integer) version_id,
       cast('2026-01-01' as timestamp) valid_from, cast(null as timestamp) valid_to
union all select 1, 12, cast('2026-02-01' as timestamp), cast(null as timestamp)
