-- With row_filter set, inverse checks must still run.
select * from (values (cast('a' as varchar)), ('b')) as t(listing_id)
