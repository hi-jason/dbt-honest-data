-- OFF as string: no partner rows are allowed, but other sources are.
select * from (values
    (cast('a' as varchar), cast('original' as varchar))
) as t(listing_id, source)
