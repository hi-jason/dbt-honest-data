-- With explicit opt-out, a single unknown identity is permitted.
select * from (values
    (cast('a' as varchar), cast(null as varchar)),
    ('b', 'exact-b')
) as t(listing_id, external_id)
