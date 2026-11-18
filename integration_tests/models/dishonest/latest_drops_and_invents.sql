-- Three ways to stop being "the source, once each": listing d is missing,
-- listing z was never in the source, and listing a is here twice.
select * from (
    values (cast('a' as varchar)), ('a'), ('b'), ('c'), ('z')
) as t(listing_id)
