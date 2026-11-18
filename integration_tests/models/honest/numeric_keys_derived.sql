-- Native integer keys must match decimal keys with equivalent numeric values.
select * from (values
    (cast(1 as integer)), (cast(2 as integer)), (cast(3 as integer))
) as t(record_id)
