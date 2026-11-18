-- Same identities as numeric_keys_derived, expressed as decimals.
select * from (
    values (cast(1.0 as decimal(12, 1))),
           (cast(2.0 as decimal(12, 1))),
           (cast(3.0 as decimal(12, 1)))
) as t(record_id)
