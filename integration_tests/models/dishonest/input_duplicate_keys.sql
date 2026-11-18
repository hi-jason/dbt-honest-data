-- Same key twice in the input: one output row is NOT an exact partition.
select * from (values (cast('a' as varchar)), ('a')) as t(listing_id)
