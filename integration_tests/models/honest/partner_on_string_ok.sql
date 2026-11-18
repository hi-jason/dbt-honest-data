-- A string-valued YES switch must behave as ON, not OFF.
select * from (values
    (cast('p1' as varchar), cast('partner' as varchar))
) as t(listing_id, source)
