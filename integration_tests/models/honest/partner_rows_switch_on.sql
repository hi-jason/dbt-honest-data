-- The switch is ON in this fixture's test, so partner rows may be here.
select * from (
    values (cast('d' as varchar), cast('partner' as varchar)), ('a', 'feed')
) as t(listing_id, source)
