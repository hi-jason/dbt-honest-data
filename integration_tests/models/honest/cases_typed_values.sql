-- Pins are compared by type: a numeric(12,2) 15.00 must match `expect: 15`,
-- and a boolean true must match `expect: true`. Compared as text, both
-- correct values would fail ('15.00' vs '15', 'true' vs 'True').
select * from (values
    (cast('Data Analyst' as varchar), cast(15.00 as numeric(12,2)), cast(true as boolean)),
    ('Head of Data', 120.50, false)
) as t(title, hourly_rate, is_remote)
