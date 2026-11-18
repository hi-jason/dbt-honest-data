-- Non-strict stages permit equality even when strict is quoted 'false'.
select cast('a' as varchar) as record_id,
       cast('2026-10-01' as date) as recorded_at,
       cast('2026-10-01' as date) as confirmed_at
