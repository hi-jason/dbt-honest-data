-- With the explicit nullable-identity exception, missing IDs cannot be
-- compared as if they referred to the same entity.
select * from (values
    (cast('row-a' as varchar), cast(null as varchar)),
    ('row-b', cast(null as varchar)),
    ('row-c', cast('   ' as varchar)),
    ('row-d', cast('  ' as varchar)),
    ('row-e', cast('exact-one' as varchar))
) as t(record_id, external_id)
