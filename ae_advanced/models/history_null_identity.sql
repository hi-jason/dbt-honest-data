-- A NULL identity would not join to another row in an overlap self-join.
select cast(null as integer) account_id, cast(99 as integer) version_id,
       cast('2026-01-01' as timestamp) valid_from,
       cast(null as timestamp) valid_to

