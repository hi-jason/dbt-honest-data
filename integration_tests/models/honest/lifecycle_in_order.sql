-- Stages in sequence, including a skipped stage (b never had an edit) and
-- an open row (c has not closed). None of that is a violation.
select * from (
    values
        (cast('a' as varchar), cast(timestamp '2026-08-01 09:00:00' as timestamp),
         cast(timestamp '2026-08-03 09:00:00' as timestamp),
         cast(timestamp '2026-08-20 09:00:00' as timestamp)),
        ('b', timestamp '2026-08-02 09:00:00', null, timestamp '2026-08-10 09:00:00'),
        ('c', timestamp '2026-08-05 09:00:00', timestamp '2026-08-05 09:00:00', null)
) as t(listing_id, listed_at, first_edited_at, closed_at)
