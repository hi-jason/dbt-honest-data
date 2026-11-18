-- Two keys, one listing: the feed's row and a hand-entered copy that
-- kept the same external id. `unique` on listing_key passes.
select * from (
    values
        (cast('feed:acme:1001' as varchar), cast(250000 as integer)),
        ('manual:acme-manual:1001', null)
) as t(listing_key, pay_min)
