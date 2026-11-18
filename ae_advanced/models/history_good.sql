-- Synthetic SCD2 history; half-open validity windows [from,to).
-- NULL valid_to means current. Two versions for account 1, one for 2.
select cast(1 as integer) account_id, cast(11 as integer) version_id,
       cast('2026-01-01' as timestamp) valid_from, cast('2026-02-01' as timestamp) valid_to
union all select 1, 12, cast('2026-02-01' as timestamp), cast(null as timestamp)
union all select 2, 21, cast('2026-01-01' as timestamp), cast(null as timestamp)
