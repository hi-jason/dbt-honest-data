-- A DISTINCT-based check would hide a duplicate within a single part.
select * from (values (cast('a' as varchar)), ('a')) as t(listing_id)
