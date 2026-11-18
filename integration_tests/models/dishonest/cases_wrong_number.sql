-- A pinned number that really is wrong must still fail: 15.00 is not 16.
select * from (values
    (cast('Data Analyst' as varchar), cast(15.00 as numeric(12,2)))
) as t(title, hourly_rate)
