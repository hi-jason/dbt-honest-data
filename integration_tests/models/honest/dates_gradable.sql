-- A model whose graded subset (rows with a stated date) is not empty.
select * from (
    values
        (cast('a' as varchar), cast(timestamp '2026-08-01 09:00:00' as timestamp)),
        ('b', null)
) as t(listing_id, posted_at)
