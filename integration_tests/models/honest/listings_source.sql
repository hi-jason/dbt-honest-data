-- The source of truth for the row-accounting fixtures: four listings.
select * from (
    values
        (cast('a' as varchar), cast('feed' as varchar)),
        ('b', 'feed'),
        ('c', 'feed'),
        ('d', 'partner')
) as t(listing_id, source)
