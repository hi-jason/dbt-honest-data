-- Both copies agree, but a pinned identity was duplicated.
-- A pure value comparison would incorrectly pass this.
select * from (values
    (cast('Data Analyst' as varchar), cast('analyst' as varchar)),
    ('Data Analyst', 'analyst')
) as t(title, role_family)
