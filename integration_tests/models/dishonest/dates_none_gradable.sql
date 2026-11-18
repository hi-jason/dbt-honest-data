-- The model has rows, and none of them is in the population the sibling
-- guard grades. That guard is green and checks nothing.
select * from (
    values
        (cast('a' as varchar), cast(null as timestamp)),
        ('b', cast(null as timestamp))
) as t(listing_id, posted_at)
