-- Two disjoint intervals share the same business/version key; the
-- no-overlap self-join using a.version_id < b.version_id misses this.
select cast(1 as integer) account_id, cast(11 as integer) version_id,
       cast('2026-01-01' as timestamp) valid_from, cast('2026-02-01' as timestamp) valid_to
union all select 1, 11, cast('2026-02-01' as timestamp), cast(null as timestamp)

