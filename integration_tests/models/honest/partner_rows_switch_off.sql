-- The switch is OFF in this fixture's test, and no partner row is here.
select * from (
    values (cast('a' as varchar), cast('feed' as varchar)), ('b', 'feed')
) as t(listing_id, source)
