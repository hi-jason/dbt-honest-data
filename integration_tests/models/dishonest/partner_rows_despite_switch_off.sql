-- The switch is OFF in this fixture's test, and a partner row is still here.
select * from (
    values (cast('d' as varchar), cast('partner' as varchar)), ('a', 'feed')
) as t(listing_id, source)
