-- Closed before it was listed: the duration is negative, the usual
-- defensive code nulls it, and the row vanishes from every median.
select * from (
    values
        (cast('a' as varchar), cast(timestamp '2026-08-10 09:00:00' as timestamp),
         cast(timestamp '2026-08-12 09:00:00' as timestamp),
         cast(timestamp '2026-08-01 09:00:00' as timestamp))
) as t(listing_id, listed_at, first_edited_at, closed_at)
