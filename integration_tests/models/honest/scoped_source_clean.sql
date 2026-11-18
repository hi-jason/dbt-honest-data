-- Strict subset: only the 'included' key must be in the filtered part.
select * from (values
    (cast('a' as varchar), cast('included' as varchar)),
    ('b', 'excluded')
) as t(listing_id, source)
