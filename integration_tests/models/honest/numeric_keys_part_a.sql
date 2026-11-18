select * from (values
    (cast(1.0 as decimal(12, 1))), (cast(2.0 as decimal(12, 1)))
) as t(record_id)
